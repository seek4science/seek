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
  `Developer` permission set cannot create IAM resources. Fargate needs a task
  execution role and a task role per service, which `awsx:ecs:FargateService`
  creates implicitly. These either need creating by the Hub or Cloud Engineer
  and looking up here, or permission to create them. The Solr instance uses
  the existing `ssm-instance-profile`.
- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Not needed until phase 2.

## Getting started

Prerequisites: [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/)
and AWS credentials for the `biofair-mc-workflow-hub` account (`aws configure
sso`). No language runtime is needed for Pulumi YAML.

The SEEK and Solr images named in the stack config (`fairdom/seek:pulumi` and
`fairdom/seek-solr:pulumi`) must be built from this branch and pushed first:

```console
docker build -t fairdom/seek:pulumi .
docker build -t fairdom/seek-solr:pulumi solr
docker push fairdom/seek:pulumi
docker push fairdom/seek-solr:pulumi
```

Then, from this directory:

```console
pulumi stack select staging
pulumi config set --secret dbPassword

pulumi preview
pulumi up
```

`pulumi config set --secret` writes the value into `Pulumi.staging.yaml`
encrypted, so the stack file can still be committed. SEEK is then at the `url`
stack output (`pulumi stack output url`).

### First deploy

The stack config starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several tasks doing so at once
would race (handover 4.4). Once the first task is healthy and the schema
exists, `webCount` can be raised. Then run the initial Solr index.

### Upgrading SEEK

Run `docker/upgrade.sh` as a one-off task against the new image before rolling
the services, one SEEK version at a time (handover 3.8).
