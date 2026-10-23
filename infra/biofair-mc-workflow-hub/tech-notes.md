# WorkflowHub: technical notes

Details behind the [README](README.md): how the deployment works, setting up
access, and operating the stack. This project, on the SEEK repository's
`pulumi` branch, is the authoritative copy; biofair-mc-infra's
`biofair-mc-workflow-hub/` holds a copy of it, updated from here. Run
commands from `data/` or `compute/`, whichever stack they concern, with
`AWS_PROFILE` and the Pulumi passphrase set (see
[AWS credentials](#aws-credentials) and
[Pulumi backend and stacks](#pulumi-backend-and-stacks)).

## How it works

Phase 1 is the managed-services design in
[`docs/SEEK-pulumi-handover.md`](../../docs/SEEK-pulumi-handover.md), cut down
to what is needed to prove SEEK runs on it:

- a VPC with public and private subnets across two Availability Zones and a
  single NAT Gateway
- an Application Load Balancer serving HTTPS at the site's domain, with an
  ACM certificate, and redirecting HTTP to HTTPS
- SEEK web and Solid Queue worker instances in Auto Scaling groups, running
  the SEEK image with Docker on Amazon Linux 2023: 1-6 web instances (the
  vCPU quota), autoscaled on CPU, requests and response time, and one worker
- MySQL on RDS (TLS required), Redis on ElastiCache (TLS and an auth token), and the filestore
  and a shared file cache on EFS, each through its own access point
- Solr on its own EC2 instance running the `fairdom/seek-solr` image, in its
  own security group, serving HTTPS only, with the index on a separate EBS
  volume, reachable as `solr.seek.internal` through a Route 53 private zone
  attached to the VPC

It creates no IAM resources: every instance uses the account's existing
`ssm-instance-profile`, and is reached through SSM. Comments in the
`Pulumi.yaml` files refer to sections of the handover as "handover 4.4" and so
on.

### Data and compute stacks

The program is two Pulumi projects, each with a `staging` stack:

| `data/` (long-lived) | `compute/` (disposable) |
|---|---|
| VPC and subnets, without a NAT gateway | NAT gateway, and the private subnets' default route through it |
| Security groups | Redis, its auth token and parameter |
| RDS, its subnet and parameter groups, the password parameter | Solr instance, its TLS key and certificate, and its DNS record |
| EFS, mount targets and access points | Load balancer, and the domain's alias record |
| Private DNS zone | Web and worker launch templates, groups and scaling policy |
| Solr index volume | |

The compute stack reads the data stack's outputs (IDs, addresses and the
password parameter's name) through a stack reference to the data stack of the
same name, so deploy the data stack first and destroy it last. Destroying the
compute stack leaves the database, filestore and Solr index as they are; a
new compute stack reattaches them. The NAT gateway is in the compute stack
because it is charged by the hour, so the data stack on its own has no route
to the internet, which nothing in it needs.

`protectData` (default true) sets Pulumi's `protect` on the database, the
filestore and the Solr volume, so a `destroy`, or a change that would
replace them, fails rather than deleting them. The staging config turns it
off, so staging can be torn down completely.

### Web and worker instances

Each group launches from a launch template whose user data:

1. installs Docker and the EFS mount helper, and mounts the filestore at
   `/mnt/filestore` and the file cache at `/mnt/cache`, each through its
   access point, so files are owned by `www-data` (uid 33) as the container
   expects;
2. reads the database password and the Redis auth token from SSM Parameter
   Store (`/<prefix>/db-password`, `/<prefix>/redis-auth-token`), in the
   stack's region, which Pulumi supplies;
3. downloads the RDS CA bundle for that region to `/etc/seek/rds-ca.pem`;
4. writes the container environment to `/etc/seek.env` (mode 600);
5. runs the SEEK container, with the two mounts as `/seek/filestore` and
   `/seek/tmp/cache` and the CA bundle at the same path:
   `docker/entrypoint.sh` on web instances, `docker/start_workers.sh` on
   worker instances.

The file cache holds the few generated files too large for Redis. Sharing it
means any web instance can serve a file another has already generated, and
the workers' scheduled cleanup job prunes it for all of them.
`BOOTSNAP_CACHE_DIR` keeps bootsnap's cache in the container instead: on the
shared cache, instances booting at once on different images left each other
stale NFS handles, and Puma failed to start with `Errno::ESTALE`.

The database requires TLS (`require_secure_transport` in `dbParams`).
`MYSQL_SSL_CA` in the environment makes SEEK connect over TLS and verify the
RDS certificate against the CA bundle, both from Rails and from the
entrypoint's `mysql` checks. A SEEK image without `MYSQL_SSL_CA` support
cannot connect at all.

Container logs stay on each instance (`docker logs seek`).

### HTTPS and the domain

The site is at `domainName` (`wfh.fairdom-seek.org` for staging), served
over HTTPS by the load balancer with a certificate from ACM. Port 80
redirects to 443.

The domain's DNS is delegated to a public Route 53 zone in the data stack
(`publicZone`): the parent domain (`fairdom-seek.org`, at GoDaddy) has NS
records for `wfh` pointing at the zone's four name servers (`pulumi stack
output nameServers` in `data/`). The data stack also requests the ACM
certificate and puts its DNS validation record in that zone, so ACM issues
and later renews it by itself; keep that record. The compute stack points
the domain at its load balancer with an alias record, so recreating the
compute, which gives the load balancer a new name, needs nothing changed by
hand.

Setting it up takes two passes of the data stack, since the certificate's
validation waits until ACM can see the delegation:

```console
cd data
pulumi up --target 'urn:pulumi:staging::biofair-mc-workflow-hub-data::aws:route53/zone:Zone::publicZone'
pulumi stack output nameServers     # add as NS records for the domain at the parent's DNS host
dig +short NS wfh.fairdom-seek.org  # until it lists them
pulumi up                           # certificate and validation
cd ../compute && pulumi up          # listener and alias record
```

Then set the site's base host in SEEK's admin settings to
`https://<domainName>`, so links in emails use it. Destroying the data stack
deletes the zone; a new zone has new name servers, and the parent's NS
records must be changed to match.

The connection on from the load balancer to the web instances is HTTPS too.
The web containers run with `NGINX_TLS`, so nginx generates a self-signed
certificate at each start and serves HTTPS on port 3000, and the target group
and its health check use HTTPS. The load balancer does not verify target
certificates, so nothing needs distributing or renewing. It passes
`X-Forwarded-Proto: https` through nginx to Rails, so SEEK generates
`https://` links.

The instances reach Solr as `solr.seek.internal` rather than by its IP. If the
Solr instance is replaced, `pulumi up` updates that record (60-second TTL),
and the web and worker instances are left alone.

### Solr

Solr's security group, `solrSg`, admits only port 8983 from the web and
worker instances. Solr cannot reach the database, Redis or EFS.

Solr serves HTTPS only. The program generates a key and a self-signed
certificate (`solrTlsKey`, `solrTlsCert`) for `solr.seek.internal` and for
`localhost`, which the image's health check uses and Jetty requires the
certificate to cover. The key is in Parameter Store
(`/<prefix>/solr-tls-key`); at boot the Solr instance builds a PKCS12
keystore from it, under a password made for that boot, for Solr's
`SOLR_SSL_*` settings. The web and worker instances trust the certificate
itself: it is in `/etc/seek/ca.d`, mounted into the container as
`SSL_CERT_DIR`, while OpenSSL still reads the image's public CAs from its
default file. `SOLR_URL` points Sunspot at `https://solr.seek.internal:8983`,
and SEEK verifies the certificate and the host name.

The certificate is valid for ten years. A `pulumi up` in its last year
replaces it, which replaces the Solr instance and rolls both groups.

User data only runs on an instance's first boot, so any change to Solr's
replaces the instance (`userDataReplaceOnChange`) rather than restarting it.
While a change to how SEEK reaches Solr rolls out, instances still on the old
settings cannot index, and SEEK rescues the errors, so those updates are
lost: run `bundle exec rake seek:reindex_all` in the worker container once
the groups have rolled.

The index is on its own 20 GB EBS volume (`solrDataSizeGb`) in the data
stack, mounted at `/var/solr`. Solr's user data finds the volume by its ID, formats it only if
it is blank, and mounts it by UUID, so a new Solr instance picks up the
existing index. Pulumi does not replace the Solr instance for a new Amazon
Linux AMI; to replace it deliberately, in `compute/`:

```console
pulumi up --replace 'urn:pulumi:staging::biofair-mc-workflow-hub-compute::aws:ec2/instance:Instance::solrInstance'
```

Pulumi detaches the volume and deletes the old instance before creating the
new one, since the volume can only be attached to one instance at a time, so
search is unavailable for a few minutes. There are no scheduled snapshots of
the volume yet (they need an IAM role from the Hub); take one by hand before
anything risky with `aws ec2 create-snapshot --volume-id <volume id>`.

To grow the volume, raise `solrDataSizeGb` and `pulumi up` the data stack; EBS resizes it in
place, at most once every six hours. Then, on the Solr instance, grow the
file system with `sudo resize2fs /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<volume id without the dash>`.
A volume cannot be shrunk.

A change to a launch template (a new image tag, a changed setting, or a new
Amazon Linux AMI from the lookup) makes `pulumi up` roll that group: each new
instance boots and passes its health check before an old one is terminated.

### Autoscaling

The web group runs between `webCount` (1) and `webCountMax` instances, six
for staging: the account's quota for standard instances is 16 vCPUs, and
Solr and the worker use 4 of them. Each instance runs `webPumaWorkers` (4)
single-threaded Puma workers, so serves four requests at a time. Pulumi does
not set the group's desired capacity, so a `pulumi up` leaves the current
number of instances alone; after changing the group by hand, use
`pulumi up --refresh` so Pulumi notices.

Four policies scale it:

| Policy | Acts on | Scales |
|---|---|---|
| `-web-cpu`, target tracking | average CPU, aiming for `webCpuTarget` (50%) | out and in |
| `-web-requests`, target tracking | the load balancer's requests a minute per instance, aiming for `webRequestTarget` (250) | out and in |
| `-web-request-surge`, step | requests per instance above `webRequestTarget` for two minutes: one instance, or two above twice that | out only |
| `-web-response-time`, step | average response time above `webResponseTimeLimit` (2 s) for three minutes: one instance, or two above twice that | out only |

The group scales out when any policy asks, and in only when both target
tracking policies agree, after 15 minutes well below target. Target
tracking's alarms need three minutes of data, which the step policies do not
wait for. Detailed monitoring reports the web instances' CPU every minute.
A new instance is left out of the averages for its first five minutes.

Measured on staging with a load test (requests arriving at a set rate, as
independent users do, rather than clients waiting for each other):

- One `t3.large` with four workers serves about 5-6 page views a second,
  about 350 requests a minute, before response times climb; its two vCPUs
  are then saturated, with memory to spare (2 GB of 7.6 used), so more
  workers would not add throughput. `webRequestTarget` is about 70% of that.
- From a sudden surge to the first new instance serving takes about seven
  minutes: three and a half to notice (CPU fires first, as the load
  balancer's request counts arrive later than EC2's CPU), and about four for
  the instance to boot, of which installing packages and pulling the image
  is two and a half. At 20 page views a second the group settled at six
  instances, each at about 45% CPU, with 0.3 s median responses.

Three settings keep scaling from making things worse:

- The load balancer's health check allows 10 s and 10 failures at 30 s
  intervals, so only five minutes of failures replace an instance. An
  overloaded instance answers `/up` slowly, since it queues behind other
  requests, and replacing it removes capacity when it is most needed.
- The group's termination policy is `NewestInstance`. Rebalancing across
  zones removes an instance without waiting for its replacement to be
  healthy, and once removed the one instance serving traffic.
- The target group routes each request to the instance with the fewest in
  progress (`least_outstanding_requests`), so a newly healthy instance takes
  its share at once and an overloaded one gets fewer.

Under sustained overload, requests still queue without limit: they take up to
the load balancer's 60-second timeout, and an instance whose connections are
exhausted makes the load balancer answer 502. Faster boots (a prepared image
or a warm pool), load shedding in nginx, and a minimum of two instances are
in `docs/pulumi-next-phase.md`, phase 3.

Watch it in the console under the group's **Activity** tab, or the CloudWatch
alarms named `TargetTracking-<group>-AlarmHigh` and `-AlarmLow`,
`<prefix>-web-request-surge` and `<prefix>-web-response-time`.

### The shared file cache and SEEK

`tmp/cache` is shared by every web and worker process on every instance, and
SEEK's code was written for one server. Two problems found so far:

- **Occasional 500s from i18n-js** (`Errno::ENOENT … tmp/cache/i18n-js.yml`),
  when instances or Puma workers start. SEEK registers i18n-js's development
  middleware in every environment; each new worker deletes its file in the
  shared cache while other processes are reading it. Needs a SEEK change:
  register the middleware in development only.
- **`Errno::ENOENT … @ dir_initialize - tmp/cache/XXX/YYY`** in jobs: Rails'
  file cache store walks its directories (`cleanup`, `delete_matched`) while
  other processes remove emptied ones. This also happens on a single server.
  Needs a SEEK change: tolerate directories that vanish during the walk.

### Why not Fargate

The `pulumi-fargate-phase-1` branch runs the same design on ECS Fargate. That
needs IAM roles for ECS (an execution role to read the database secret and
write logs, and task roles), and permission to pass them to ECS. The
`Developer` permission set can't create IAM roles or pass them to ECS, so
moving to Fargate later needs those roles and that permission from the Hub,
or a permission set that has them. The data stores, load balancer and Solr
carry forward unchanged either way.

### Next phase

What each later phase adds, what each part needs and what blocks it is in
[`docs/pulumi-next-phase.md`](../../docs/pulumi-next-phase.md).

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Staging delegates
  `wfh.fairdom-seek.org` to Route 53 and uses an ACM certificate; a
  production domain may need agreeing with the Hub.

## Setting up

### Tools

You need the [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/),
the AWS CLI v2, and the AWS CLI's
[`session-manager-plugin`](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
for shells on the instances. No language runtime is needed for Pulumi YAML.
On Ubuntu 24.04, which no longer packages the AWS CLI:

```console
curl -fsSL https://get.pulumi.com | sh
sudo snap install aws-cli --classic
curl -fsSL https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb -o /tmp/session-manager-plugin.deb
sudo dpkg -i /tmp/session-manager-plugin.deb
```

The Pulumi installer adds `~/.pulumi/bin` to `PATH` in `~/.bashrc`; open a
new shell afterwards.

### AWS credentials

Sign in through the BioFAIR Hub's IAM Identity Center:

```console
aws configure sso
```

| Prompt | Answer |
|---|---|
| SSO start URL | the Hub's AWS access portal URL (`https://d-….awsapps.com/start`) |
| SSO region | `eu-north-1`, where the Hub's Identity Center is. Any other region fails with `InvalidRequestException` at `RegisterClient` |
| SSO registration scopes | the default, `sso:account:access` |
| Account and role | the WorkflowHub account, with your permission set (e.g. `Developer`) |
| Default client Region | `eu-west-2`, where the resources go |
| Profile name | e.g. `workflowhub` |

Then, in every shell you use Pulumi or the AWS CLI from, select that profile.
Without it Pulumi fails with "No valid credential sources found", and the AWS
CLI with "You must specify a region":

```console
export AWS_PROFILE=workflowhub
```

The sign-in lasts as long as the Hub's Identity Center session allows,
typically a working day. When it expires, sign in again with
`aws sso login --profile workflowhub`.

### Images

The SEEK and Solr images named in the stack config
(`fairdom/seek:workflowhub-pulumi` and `fairdom/seek-solr:pulumi`) are built
from the same commit of this branch of the SEEK repository, so the Solr
configset matches the code, and pushed by hand from the repository root:

```console
docker build -t fairdom/seek:workflowhub-pulumi .
docker build -t fairdom/seek-solr:pulumi solr
docker push fairdom/seek:workflowhub-pulumi
docker push fairdom/seek-solr:pulumi
```

### Pulumi backend and stacks

Each project's `Pulumi.staging.yaml` holds its stack's configuration, but the
stacks themselves, which record what Pulumi has deployed, have to be created
in a backend. The shared backend is still an open question. Until it is
settled, use a local one, which keeps state in `~/.pulumi` on your machine:

```console
export PULUMI_CONFIG_PASSPHRASE_FILE=~/.workflowhub-passphrase   # a file only you can read
pulumi login --local
cd data && pulumi stack init staging
pulumi config set --secret dbPassword "$(openssl rand -hex 16)"
cd ../compute && pulumi stack init staging
```

A local backend encrypts secrets with a passphrase, which every command needs.
Give it through `PULUMI_CONFIG_PASSPHRASE_FILE` (or
`PULUMI_CONFIG_PASSPHRASE`), not at the prompt, and use the same one for both
stacks: the compute stack's stack reference has to open the data stack's
state, and cannot prompt for its passphrase. Typed at the prompt, the compute
stack's preview stalls and fails with `constructing secrets manager of type
"passphrase": ... EOF`; with different passphrases, it fails with
`incorrect passphrase`.

`stack init` adds an `encryptionsalt` to each `Pulumi.staging.yaml`, and
`config set --secret` adds the encrypted `dbPassword` to the data stack's.
They are tied to your local stacks, so don't commit them.

Use letters and digits only for `dbPassword`, 8-41 characters, as the command
above does. SEEK's database config and startup scripts use it unquoted, so
YAML or shell special characters break the connection.

The Redis auth token is generated by the program (`redisAuthToken`, 32
letters and digits) and kept only in the state, encrypted like the database
password, and in Parameter Store. To replace it, for instance after it has
been exposed:

```console
pulumi up --replace 'urn:pulumi:staging::biofair-mc-workflow-hub-compute::random:index/randomPassword:RandomPassword::redisAuthToken'
```

A changed token replaces the Redis group (`replaceOnChanges`), because
changing it in place leaves it optional until a separate step; the instances
are then refreshed, and sessions and the cache start empty.

That command is run in `compute/`, like everything else about Redis, Solr and
the instances. A new compute stack generates a new token anyway.

State in a local backend is only on your machine, so use it for previewing and
trying the deployment, not for one anyone else needs to manage.

## Operating the stack

### First deploy

Deploy the data stack, then the compute stack. The compute stack config
starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several instances doing so at once
would race (handover 4.4). Once the first instance is healthy and the schema
exists, `webCount` can be raised. Then run the initial Solr index.

After `pulumi up`, SEEK is at the compute stack's `url` output once the web instance has
booted and passed its health check, which takes several minutes on first
boot. Until then the load balancer returns 502 or 503.

The first Auto Scaling group created in an account makes AWS create the
`AWSServiceRoleForAutoScaling` service-linked role. The groups' first launch
can come before the new role has propagated, failing with "Access denied when
attempting to assume role" or "Authentication Failure". Auto Scaling retries
by itself and the instances launch a minute later, but `pulumi up` has
already reported both groups as failed. Run `pulumi up --refresh` to record
the groups as they are; this only happens once per account.

### Reaching the instances

Find an instance's ID in the console or, in `compute/`, with:

```console
aws ec2 describe-instances \
  --filters Name=tag:aws:autoscaling:groupName,Values="$(pulumi stack output webGroupName)" \
            Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId' --output text
```

then open a shell with `aws ssm start-session --target <instance-id>` and
`sudo -i`. The container is `seek` on web instances and `seek-workers` on
worker instances; boot progress is in `/var/log/cloud-init-output.log`.

In the AWS console (region Europe (London)), the same boot log is under the
instance's **Actions → Monitor and troubleshoot → Get system log**, and
**Connect → Session Manager** opens a shell in the browser.

### When an instance fails to start

If an instance's user data failed, fix the cause and replace the instance:
its user data only runs on first boot. `aws autoscaling
start-instance-refresh` does this for a group, but stalls when the group's
only instance is unhealthy, since it waits for that instance first. In that
case cancel the refresh and terminate the instance; the group launches a
replacement:

```console
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <instance-id> --no-should-decrement-desired-capacity
```

### Upgrading SEEK

One SEEK version at a time (handover 3.8): from a shell on a web instance, run
the upgrade with the new image,

```console
docker run --rm --env-file /etc/seek.env \
  -v /mnt/filestore:/seek/filestore -v /mnt/cache:/seek/tmp/cache \
  -v /etc/seek/rds-ca.pem:/etc/seek/rds-ca.pem:ro \
  fairdom/seek:<new-tag> docker/upgrade.sh
```

then set `seekImage` to the new tag in the compute stack config and
`pulumi up` there, which rolls both groups onto it.

### Pausing and resuming

To stop paying for compute but keep the data, destroy the compute stack and
stop the database:

```console
# Pause
cd compute && pulumi destroy
cd ../data
DB=$(aws rds describe-db-instances \
  --query "DBInstances[?Endpoint.Address=='$(pulumi stack output databaseEndpoint)'].DBInstanceIdentifier" \
  --output text)
aws rds stop-db-instance --db-instance-identifier "$DB"
```

```console
# Resume: start the database, wait, then bring the compute back.
# A database still stopping after a pause cannot be started yet.
db_status() { aws rds describe-db-instances --db-instance-identifier "$DB" --query 'DBInstances[0].DBInstanceStatus' --output text; }
until [ "$(db_status)" = stopped ]; do sleep 15; done
aws rds start-db-instance --db-instance-identifier "$DB"
aws rds wait db-instance-available --db-instance-identifier "$DB"
cd ../compute && pulumi up
```

The new compute finds the existing database, filestore and Solr index, and
carries on without setting them up again. Redis starts empty, so everyone is
logged out. Set `DB` again as above if resuming from a new shell. Starting a
stopped database takes 5-10 minutes, including a recovery step; its progress
is on the database's **Logs & events** tab in the console.

Paused, only storage is billed: roughly $0.02 an hour for the database's
storage, the filestore and the Solr volume. AWS restarts a stopped database
automatically after seven days, so for a longer pause, stop it again when it
restarts; running, the database costs about $0.09 an hour more.

### Tearing down

Destroy the compute stack first, then the data stack:

```console
cd compute && pulumi destroy && pulumi stack rm --preserve-config staging
cd ../data && pulumi destroy && pulumi stack rm --preserve-config staging
```

`--preserve-config` keeps each `Pulumi.staging.yaml`, which `stack rm`
otherwise deletes along with the stack. They still hold the old stacks'
`encryptionsalt` and the encrypted `dbPassword`; remove those lines before
creating the stacks again with `pulumi stack init`.

`destroy` needs the same machine, local backend and passphrase as `up`, and a
current AWS sign-in. Every resource is tagged `ManagedBy: pulumi` and
`Environment: staging`, so anything left behind can be found in the console's
Tag Editor.

The staging data stack config turns off `protectData`, the database's
deletion protection and its final snapshot (`dbDeletionProtection`,
`dbSkipFinalSnapshot`), so `destroy` deletes everything outright. All three
default to on, for stacks holding real data. There, `destroy` refuses to
delete the protected database, filestore and Solr volume, and the database
leaves a `<prefix>-final` snapshot when it is deleted. Changing these settings
only takes effect through `pulumi up`, not during a `destroy`; to delete
protected resources, set `protectData` to false and `pulumi up` first.

### Costs

At London on-demand prices, staging costs roughly $0.38 an hour for
everything except the web instances (the worker and Solr instances, RDS,
ElastiCache, the load balancer and the NAT gateway), plus about $0.10 an hour
for each web instance: about $0.48 an hour at the minimum of one, $0.68 at
three and $0.98 at staging's maximum of six. A busy `t3` instance adds about
$0.03 an hour in CPU credits. With only the data stack up, about $0.11 an
hour with the database running and $0.02 with it stopped.
