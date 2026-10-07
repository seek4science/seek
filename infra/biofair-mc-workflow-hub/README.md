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

The managed-services design, cut down to what is needed to prove SEEK runs on
it. Not yet deployed or previewed against AWS.

- a VPC with public and private subnets across two Availability Zones and a
  single NAT Gateway
- an Application Load Balancer, HTTP only, at its own AWS hostname
- SEEK web and Solid Queue worker services on ECS Fargate, fixed task counts
- MySQL on RDS, Redis on ElastiCache (TLS, no auth token), and the filestore on
  EFS
- Solr on its own EC2 instance, with the index on the instance's root volume

Every resource here carries forward unchanged into phase 2.

## Phase 2

Added once phase 1 works, as designed in the handover:

- **HTTPS and a real domain**: an ACM certificate on a 443 listener, HTTP
  redirecting to it, and a Route 53 record. Waits on the DNS question below.
- **Front-end autoscaling** on CPU, 2-8 tasks.
- **Durable Solr index**: a standalone, protected EBS volume that survives
  instance replacement, with nightly DLM snapshots (handover 3.6). Needs an IAM
  role for DLM.
- **Private DNS name for Solr** (`solr.seek.internal`) rather than its IP.
- **Shared file cache**: a second EFS access point for `tmp/cache` (handover
  3.3), worthwhile once there are several front-end tasks.
- **Redis auth token**, held in Secrets Manager.
- **EFS backups.**

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **IAM role creation.** biofair-mc-infra's code works on the basis that the
  `Developer` permission set cannot create IAM resources. `pulumi preview`
  does not check this; `pulumi up` would fail at the first role. This program
  creates:
  - `<prefix>-ecs-execution`, shared by both services: the AWS-managed
    `AmazonECSTaskExecutionRolePolicy` (image pulls, logs) plus an inline
    policy allowing `secretsmanager:GetSecretValue` on the database secret
    only. Without that inline policy the tasks cannot start.
  - a task role per service, created by `awsx:ecs:FargateService`, with no
    policies.

  These either need creating by the Hub or Cloud Engineer and passing in by
  ARN, or permission to create them. The Solr instance uses the existing
  `ssm-instance-profile`.
- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Not needed until phase 2.

## Getting started

### Tools

You need the [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/)
and the AWS CLI v2, and optionally the AWS CLI's
[`session-manager-plugin`](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
for a shell on the Solr instance. No language runtime is needed for Pulumi
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

`pulumi preview` creates nothing. SEEK is then at the `url` stack output
(`pulumi stack output url`).

### First deploy

The stack config starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several tasks doing so at once
would race (handover 4.4). Once the first task is healthy and the schema
exists, `webCount` can be raised. Then run the initial Solr index.

### Upgrading SEEK

Run `docker/upgrade.sh` as a one-off task against the new image before rolling
the services, one SEEK version at a time (handover 3.8).

### Tearing down

```console
pulumi destroy
pulumi stack rm staging
```

`destroy` needs the same machine, local backend and passphrase as `up`, and a
current AWS sign-in. Every resource is tagged `ManagedBy: pulumi` and
`Environment: staging`, so anything left behind can be found in the console's
Tag Editor. RDS is created with deletion protection and takes a final
snapshot, so `destroy` stops at the database until protection is turned off.
