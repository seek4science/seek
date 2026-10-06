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

## Current scope

The full design, not yet deployed or previewed against AWS:

- a VPC with public and private subnets across two Availability Zones and a
  single NAT Gateway
- an Application Load Balancer in front of SEEK web tasks on ECS Fargate,
  autoscaled on CPU
- a Solid Queue worker service on ECS Fargate
- MySQL on RDS, Redis on ElastiCache, and the filestore and file cache on EFS
- Solr on its own EC2 instance, with the index on a standalone EBS volume
  that outlives the instance, snapshotted nightly

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **IAM role creation.** biofair-mc-infra's code works on the basis that the
  `Developer` permission set cannot create IAM resources. This program creates
  an ECS task execution role and task role per service (implicitly, via
  `awsx:ecs:FargateService`) and a role for the Solr snapshot policy. These
  either need creating by the Hub or Cloud Engineer and looking up here, or
  permission to create them. The Solr instance already uses the existing
  `ssm-instance-profile` rather than its own role.
- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **DNS and ACM certificate issuance.** `domainName`, `certificateArn` and
  `hostedZoneId` in the stack config are placeholders until it is known who
  owns the hosted zone and issues the certificate.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.

## Getting started

Prerequisites: [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/)
and AWS credentials for the `biofair-mc-workflow-hub` account (`aws configure
sso`). No language runtime is needed for Pulumi YAML.

The SEEK and Solr images named in the stack config (`fairdom/seek:pulumi` and
`fairdom/seek-solr:pulumi`) must be built from the `pulumi` branch and pushed
first:

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
pulumi config set --secret redisAuthToken

pulumi preview
pulumi up
```

`pulumi config set --secret` writes the values into `Pulumi.staging.yaml`
encrypted, so the stack file can still be committed.

### First deploy

The stack config starts with `webCount: 1`. On an empty database the SEEK web
container runs `rake db:setup` at boot, and several tasks doing so at once
would race (handover 4.4). Once the first task is healthy and the schema
exists, raise `webCount`. Then run the initial Solr index; it is slow, but
later deploys reattach the existing volume and do not reindex.

### Upgrading SEEK

Run `docker/upgrade.sh` as a one-off task against the new image before rolling
the services, one SEEK version at a time (handover 3.8).
