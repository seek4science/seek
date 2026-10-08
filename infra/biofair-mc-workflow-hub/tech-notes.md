# WorkflowHub: technical notes

Details behind the [README](README.md): how the deployment works, setting up
access, and operating the stack. Run commands from this directory with
`AWS_PROFILE` set (see [AWS credentials](#aws-credentials)).

## How it works

Phase 1 is the managed-services design in
[`docs/SEEK-pulumi-handover.md`](../../docs/SEEK-pulumi-handover.md), cut down
to what is needed to prove SEEK runs on it:

- a VPC with public and private subnets across two Availability Zones and a
  single NAT Gateway
- an Application Load Balancer at its own AWS hostname, serving HTTPS with a
  self-signed certificate, and redirecting HTTP to HTTPS
- SEEK web and Solid Queue worker instances in Auto Scaling groups, running
  the SEEK image with Docker on Amazon Linux 2023: 1-8 web instances,
  autoscaled on CPU, and one worker
- MySQL on RDS, Redis on ElastiCache (TLS, no auth token), and the filestore
  on EFS
- Solr on its own EC2 instance running the `fairdom/seek-solr` image, with the
  index on the instance's root volume, reachable as `solr.seek.internal`
  through a Route 53 private zone attached to the VPC

It creates no IAM resources: every instance uses the account's existing
`ssm-instance-profile`, and is reached through SSM. Comments in `Pulumi.yaml`
refer to sections of the handover as "handover 4.4" and so on.

### Web and worker instances

Each group launches from a launch template whose user data:

1. installs Docker and the EFS mount helper, and mounts the filestore at
   `/mnt/filestore` through its access point, so files are owned by
   `www-data` (uid 33) as the container expects;
2. reads the database password from SSM Parameter Store
   (`/<prefix>/db-password`);
3. writes the container environment to `/etc/seek.env` (mode 600);
4. runs the SEEK container: `docker/entrypoint.sh` on web instances,
   `docker/start_workers.sh` on worker instances.

Container logs stay on each instance (`docker logs seek`).

### HTTPS

Pulumi's `tls` provider generates a private key and a self-signed certificate
(valid for a year, named `<prefix>.seek.internal`), which the program imports
into ACM for the load balancer's 443 listener. Port 80 redirects to 443.
Browsers warn about the certificate; accept the warning to continue. The
private key is held encrypted in the Pulumi state. The load balancer only
accepts certificates for a fully qualified domain name, hence the
`.seek.internal` name, though nothing resolves it.

The load balancer terminates TLS and passes `X-Forwarded-Proto: https`
through nginx to Rails, so SEEK generates `https://` links. A real domain
replaces only the certificate (`docs/pulumi-next-phase.md`, phase 4).

The instances reach Solr as `solr.seek.internal` rather than by its IP. If the
Solr instance is replaced, `pulumi up` updates that record (60-second TTL),
and the web and worker instances are left alone.

A change to a launch template (a new image tag, a changed setting, or a new
Amazon Linux AMI from the lookup) makes `pulumi up` roll that group: each new
instance boots and passes its health check before an old one is terminated.

### Autoscaling

The web group runs between `webCount` (1) and `webCountMax` (8) instances. A
target tracking policy adds instances while average CPU across the group is
above `webCpuTarget` (50%), and removes them once it has been well below
(under 35%) for 15 minutes. A new instance is left out of the average for
its first five minutes, while it boots and pulls the image. Pulumi does not
set the group's desired capacity, so a `pulumi up` leaves the current number
of instances alone.

EC2's basic monitoring reports CPU every five minutes, so scaling reacts a
few minutes late in both directions. Watch it in the console under the
group's **Activity** tab, or the CloudWatch alarms named
`TargetTracking-<group>-AlarmHigh` and `-AlarmLow`.

### Why not Fargate

The `pulumi-fargate-phase-1` branch runs the same design on ECS Fargate. That
needs IAM roles for ECS (an execution role to read the database secret and
write logs, and task roles), and permission to pass them to ECS. The
`Developer` permission set can't create IAM roles or pass them to ECS, so
moving to Fargate later needs those roles and that permission from the Hub,
or a permission set that has them. The data stores, load balancer and Solr
carry forward unchanged either way.

### Next phase

What phase 2 adds, what each part needs and what blocks it is in
[`docs/pulumi-next-phase.md`](../../docs/pulumi-next-phase.md).

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Not needed until phase 4.

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

### Pulumi backend and stack

`Pulumi.staging.yaml` holds the stack's configuration, but the stack itself,
which records what Pulumi has deployed, has to be created in a backend. The
shared backend is still an open question. Until it is settled, use a local
one, which keeps state in `~/.pulumi` on your machine:

```console
pulumi login --local
pulumi stack init staging
pulumi config set --secret dbPassword "$(openssl rand -hex 16)"
```

A local backend encrypts secrets with a passphrase, which `stack init` asks
for and every later command needs. Set `PULUMI_CONFIG_PASSPHRASE`, or point
`PULUMI_CONFIG_PASSPHRASE_FILE` at a file only you can read, to avoid the
prompt. `stack init` adds an `encryptionsalt` to `Pulumi.staging.yaml`, and
`config set --secret` adds the encrypted `dbPassword`. Both are tied to your
local stack, so don't commit them.

Use letters and digits only for `dbPassword`, 8-41 characters, as the command
above does. SEEK's database config and startup scripts use it unquoted, so
YAML or shell special characters break the connection.

State in a local backend is only on your machine, so use it for previewing and
trying phase 1, not for a deployment anyone else needs to manage.

## Operating the stack

### First deploy

The stack config starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several instances doing so at once
would race (handover 4.4). Once the first instance is healthy and the schema
exists, `webCount` can be raised. Then run the initial Solr index.

After `pulumi up`, SEEK is at the `url` stack output once the web instance has
booted and passed its health check, which takes several minutes on first
boot. Until then the load balancer returns 502. The address is HTTPS with a
self-signed certificate, so the browser warns first.

The first Auto Scaling group created in an account makes AWS create the
`AWSServiceRoleForAutoScaling` service-linked role. The groups' first launch
can come before the new role has propagated, failing with "Access denied when
attempting to assume role" or "Authentication Failure". Auto Scaling retries
by itself and the instances launch a minute later, but `pulumi up` has
already reported both groups as failed. Run `pulumi up --refresh` to record
the groups as they are; this only happens once per account.

### Reaching the instances

Find an instance's ID in the console or with:

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
docker run --rm --env-file /etc/seek.env -v /mnt/filestore:/seek/filestore \
  fairdom/seek:<new-tag> docker/upgrade.sh
```

then set `seekImage` to the new tag in the stack config and `pulumi up`, which
rolls both groups onto it.

### Pausing and resuming

`pulumi destroy` deletes the data too. To stop paying for compute but keep the
database, filestore and Solr index, stop or empty the parts that compute and
leave the storage:

```console
# Pause: empty both groups, then stop Solr and the database
for g in "$(pulumi stack output webGroupName)" "$(pulumi stack output workerGroupName)"; do
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$g" \
    --min-size 0 --max-size 0 --desired-capacity 0
done
SOLR=$(aws ec2 describe-instances \
  --filters Name=private-ip-address,Values="$(pulumi stack output solrPrivateIp)" \
  --query 'Reservations[].Instances[].InstanceId' --output text)
DB=$(aws rds describe-db-instances \
  --query "DBInstances[?Endpoint.Address=='$(pulumi stack output databaseEndpoint)'].DBInstanceIdentifier" \
  --output text)
aws ec2 stop-instances --instance-ids "$SOLR"
aws rds stop-db-instance --db-instance-identifier "$DB"
```

```console
# Resume: start the database and Solr, wait, then restore the groups.
# A database still stopping after a pause cannot be started yet.
db_status() { aws rds describe-db-instances --db-instance-identifier "$DB" --query 'DBInstances[0].DBInstanceStatus' --output text; }
until [ "$(db_status)" = stopped ]; do sleep 15; done
aws rds start-db-instance --db-instance-identifier "$DB"
aws ec2 start-instances --instance-ids "$SOLR"
aws rds wait db-instance-available --db-instance-identifier "$DB"
pulumi up --refresh
```

`pulumi up --refresh` notices the emptied groups and sets their sizes back
from the stack config, starting the web group at `webCount`. The new instances find the existing database
and carry on, without setting it up again. Set `SOLR` and `DB` again as above
if resuming from a new shell. Starting a stopped database takes 5-10 minutes,
including a recovery step; its progress is on the database's **Logs &
events** tab in the console.

While paused, the stack still costs roughly a third of its running cost: the
NAT gateway, load balancer and ElastiCache cannot be stopped, and the database
and filestore are billed for storage. AWS restarts a stopped database
automatically after seven days, so for a longer pause, stop it again when it
restarts. Paying nothing while keeping the data needs a snapshot to restore
from, or the data stores in a stack of their own (phase 3); neither is set up
yet.

### Tearing down

```console
pulumi destroy
pulumi stack rm --preserve-config staging
```

`--preserve-config` keeps `Pulumi.staging.yaml`, which `stack rm` otherwise
deletes along with the stack. It still holds the old stack's `encryptionsalt`
and encrypted `dbPassword`; remove those lines before creating the stack again
with `pulumi stack init`.

`destroy` needs the same machine, local backend and passphrase as `up`, and a
current AWS sign-in. Every resource is tagged `ManagedBy: pulumi` and
`Environment: staging`, so anything left behind can be found in the console's
Tag Editor.

The staging stack config turns off the database's deletion protection and
final snapshot (`dbDeletionProtection`, `dbSkipFinalSnapshot`), so `destroy`
deletes it outright. Both default to on, for stacks holding real data; there,
`destroy` stops at the database until protection is turned off, and leaves a
`<prefix>-final` snapshot. Changing these settings only takes effect through
`pulumi up`, not during a `destroy`.

### Costs

At London on-demand prices, the staging stack costs roughly $0.38 an hour
for everything except the web instances (the worker and Solr instances, RDS,
ElastiCache, the load balancer and the NAT gateway), plus about $0.10 an hour
for each web instance: about $0.48 an hour at the minimum of one, $0.68 at
three and $1.17 at the maximum of eight. A busy `t3` instance adds about
$0.03 an hour in CPU credits. Paused, roughly $0.15 an hour.
