# WorkflowHub

Pulumi component provisioning the `biofair-mc-workflow-hub` account's AWS
infrastructure for WorkflowHub, which runs SEEK. It follows the layout and
conventions of
[biofair-mc-infra](https://github.com/BioFAIRUK/biofair-mc-infra)'s
`biofair-mc-galaxy/`, but is written in Pulumi YAML rather than Python, so it
does not use that repository's `biofair_mc_common` package.

See [`docs/SEEK-pulumi-handover.md`](../../docs/SEEK-pulumi-handover.md) for
the design: architecture, the decision log, and how SEEK's docker-compose
services map onto AWS. Comments in `Pulumi.yaml` refer to its sections as
"handover 4.4" and so on. For the AWS account context (terms, confirmed facts,
who does what), see biofair-mc-infra's `docs/aws-context.md`.

## Current scope: phase 1

The managed-services design in the handover, cut down to what is needed to
prove SEEK runs on it, and with the front-end and workers on EC2 Auto Scaling
groups instead of ECS Fargate, so that it creates **no IAM resources** and can
be deployed with the `Developer` permission set. Previewed against AWS
(`pulumi preview`, 47 resources); not yet deployed.

- a VPC with public and private subnets across two Availability Zones and a
  single NAT Gateway
- an Application Load Balancer, HTTP only, at its own AWS hostname
- SEEK web and Solid Queue worker instances, each in an Auto Scaling group of
  fixed size, running the SEEK image with Docker on Amazon Linux 2023
- MySQL on RDS, Redis on ElastiCache (TLS, no auth token), and the filestore on
  EFS
- Solr on its own EC2 instance, with the index on the instance's root volume

### How the web and worker instances work

Each group launches from a launch template whose user data:

1. installs Docker and the EFS mount helper, and mounts the filestore at
   `/mnt/filestore` through its access point, so files are owned by
   `www-data` (uid 33) as the container expects;
2. reads the database password from SSM Parameter Store
   (`/<prefix>/db-password`), which the instance profile is allowed to do;
3. writes the container environment to `/etc/seek.env` (mode 600);
4. runs the SEEK container: `docker/entrypoint.sh` on web instances,
   `docker/start_workers.sh` on worker instances.

The instances use the account's existing `ssm-instance-profile` and are
reached through SSM. Container logs stay
on each instance (`docker logs seek`).

A change to a launch template (a new image tag, a changed setting, or a new
Amazon Linux AMI from the lookup) makes `pulumi up` roll that group: each new
instance boots and passes its health check before an old one is terminated.

### Why not Fargate

The `pulumi-fargate-phase-1` branch runs the same design on ECS Fargate. That
needs IAM roles for ECS (an execution role to read the database secret and
write logs, and task roles), and permission to pass them to ECS. The
`Developer` permission set can't create IAM roles or pass them to ECS, so
moving to Fargate later needs those roles and that permission from the Hub,
or a permission set that has them.

The data stores, load balancer and Solr carry forward unchanged either way.

## Phase 2

Added once phase 1 works, as designed in the handover:

- **HTTPS and a real domain**: an ACM certificate on a 443 listener, HTTP
  redirecting to it, and a Route 53 record. Waits on the DNS question below.
- **Front-end autoscaling** on CPU, 2-8 instances, using a target-tracking
  policy on the web group.
- **Durable Solr index**: a standalone, protected EBS volume that survives
  instance replacement, with nightly DLM snapshots (handover 3.6). Needs an IAM
  role for DLM.
- **Private DNS name for Solr** (`solr.seek.internal`) rather than its IP.
- **Shared file cache**: a second EFS access point for `tmp/cache` (handover
  3.3), worthwhile once there are several front-end instances.
- **Redis auth token**, held in Secrets Manager.
- **EFS backups.**
- **Container logs in CloudWatch**, which needs CloudWatch permissions on the
  instance role.

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Not needed until phase 2.

## Getting started

### Tools

You need the [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/),
the AWS CLI v2, and the AWS CLI's
[`session-manager-plugin`](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
for shells on the instances. No language runtime is needed for Pulumi
YAML. On Ubuntu 24.04, which no longer packages the AWS CLI:

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

The SEEK and Solr images named in the stack config (`fairdom/seek:pulumi` and
`fairdom/seek-solr:pulumi`) must be built from this branch and pushed first:

```console
docker build -t fairdom/seek:pulumi .
docker build -t fairdom/seek-solr:pulumi solr
docker push fairdom/seek:pulumi
docker push fairdom/seek-solr:pulumi
```

### Pulumi backend and stack

`Pulumi.staging.yaml` holds the stack's configuration, but the stack itself,
which records what Pulumi has deployed, has to be created in a backend. The
shared backend is still an open question (see above). Until it is settled,
use a local one, which keeps state in `~/.pulumi` on your machine:

```console
pulumi login --local
pulumi stack init staging
pulumi config set --secret dbPassword
```

A local backend encrypts secrets with a passphrase, which `stack init` asks
for and every later command needs. Set `PULUMI_CONFIG_PASSPHRASE`, or point
`PULUMI_CONFIG_PASSPHRASE_FILE` at a file only you can read, to avoid the
prompt. `stack init` adds an `encryptionsalt` to `Pulumi.staging.yaml`, and
`config set --secret` adds the encrypted `dbPassword`. Both are tied to your
local stack, so don't commit them.

State in a local backend is only on your machine, so use it for previewing and
trying phase 1, not for a deployment anyone else needs to manage.

### Preview and deploy

From this directory:

```console
pulumi stack select staging
pulumi preview
pulumi up
```

`pulumi preview` creates nothing. After `up`, SEEK is at the `url` stack
output (`pulumi stack output url`) once the web instance has booted and passed
its health check, which takes several minutes on first boot.

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

### First deploy

The stack config starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several instances doing so at once
would race (handover 4.4). Once the first instance is healthy and the schema
exists, `webCount` can be raised. Then run the initial Solr index.

The first Auto Scaling group created in an account makes AWS create the
`AWSServiceRoleForAutoScaling` service-linked role. The groups' first launch
can come before the new role has propagated, failing with "Access denied when
attempting to assume role" or "Authentication Failure". Auto Scaling retries
by itself and the instances launch a minute later, but `pulumi up` has
already reported both groups as failed. Run `pulumi up --refresh` to record
the groups as they are; this only happens once per account.

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
leave the storage. Run these from this directory, with `AWS_PROFILE` set:

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

`pulumi up --refresh` notices the emptied groups and sets them back to
`webCount` and `workerCount`. The new instances find the existing database
and carry on, without setting it up again. Set `SOLR` and `DB` again as above
if resuming from a new shell.

While paused, the stack still costs roughly a third of its running cost: the
NAT gateway, load balancer and ElastiCache cannot be stopped, and the database
and filestore are billed for storage. AWS restarts a stopped database
automatically after seven days, so for a longer pause, stop it again when it
restarts. Paying nothing while keeping the data needs a snapshot to restore
from, or the data stores in a stack of their own; neither is set up yet.

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
