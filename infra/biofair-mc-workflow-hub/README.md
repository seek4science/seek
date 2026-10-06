# WorkflowHub

Pulumi component provisioning the `biofair-mc-workflow-hub` account's AWS
infrastructure for WorkflowHub, which runs SEEK. It follows the layout and
conventions of
[biofair-mc-infra](https://github.com/BioFAIRUK/biofair-mc-infra)'s
`biofair-mc-galaxy/`, but is written in Pulumi YAML rather than Python, so it
does not use that repository's `biofair_mc_common` package.

For the AWS account context (terms, confirmed facts, who does what), see
biofair-mc-infra's `docs/aws-context.md`.
[`docs/SEEK-pulumi-handover.md`](../../docs/SEEK-pulumi-handover.md) describes
the alternative, managed-services design (ECS Fargate, RDS, ElastiCache, EFS).

## Current scope: phase 1

The same shape as `biofair-mc-galaxy/`'s phase 1: a VPC with public and private
subnets across two Availability Zones, a single NAT Gateway, a security group
with no inbound rules, and one EC2 instance. No load balancer.

The instance runs Ubuntu 24.04. On first boot it installs Docker, clones the
SEEK repository at `seekRepoRef` and runs its `docker-compose.yml` unchanged:
SEEK, the Solid Queue workers, MySQL, Solr and Redis, all on the one machine.
`seekImage` overrides the image the compose file names, through a
`docker-compose.override.yml`.

Things to know:

- **No new IAM resources.** The instance uses the account's existing
  `ssm-instance-profile`, so this is deployable with the `Developer`
  permission set.
- **No secrets in the stack.** The compose services use the passwords in the
  repository's `docker/db.env` and `docker/redis.env`. MySQL and Redis are
  reachable only on the compose network inside the instance, and the instance
  accepts no inbound traffic, but change them before holding real data.
- **Everything lives on the instance's root volume**, in Docker volumes.
  Replacing the instance loses the data, so Pulumi is told to ignore changes
  to the AMI and the user data rather than replace it.
- **Not yet deployed or previewed against AWS.**

## Phase 2

Depending on what phase 1 shows, either:

- harden this instance: a load balancer with HTTPS and a domain, a separate
  data volume with snapshots, passwords from Secrets Manager, and moving MySQL
  to RDS; or
- move to the managed-services design in the handover, which scales the
  front-end horizontally but needs IAM roles for ECS.

## Open questions

Shared with biofair-mc-infra's `docs/aws-context.md`, "Still needs a decision":

- **VPC/networking ownership.** This program creates its own VPC, pending an
  answer.
- **Pulumi state backend.** Not set up yet; must be the same for everyone
  working on this stack.
- **DNS and ACM certificate issuance.** Not needed until there is a load
  balancer.

## Getting started

Prerequisites: [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/),
AWS credentials for the `biofair-mc-workflow-hub` account (`aws configure
sso`), and the AWS CLI's
[`session-manager-plugin`](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).
No language runtime is needed for Pulumi YAML.

From this directory:

```console
pulumi stack select staging
pulumi preview
pulumi up
```

First boot takes several minutes: package installs, the clone, image pulls,
and SEEK creating its database. Progress is in `/var/log/cloud-init-output.log`
on the instance.

### Reaching SEEK

There is no public endpoint. Forward SEEK's port to your machine over SSM:

```console
aws ssm start-session \
  --target "$(pulumi stack output instanceId)" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3000"],"localPortNumber":["3000"]}'
```

then open <http://localhost:3000>. For a shell on the instance, use
`aws ssm start-session --target "$(pulumi stack output instanceId)"`; the
compose project is in `/opt/seek`.

### Upgrading SEEK

On the instance, as for any docker-compose SEEK installation: update the
checkout in `/opt/seek` and the image in `docker-compose.override.yml`, then
`docker compose pull`, run `docker/upgrade.sh` in a one-off container, and
`docker compose up -d`, one SEEK version at a time.
