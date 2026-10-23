# WorkflowHub

Pulumi component provisioning the `biofair-mc-workflow-hub` account's AWS
infrastructure for WorkflowHub, which runs SEEK. It is written in Pulumi YAML,
as two projects: `data/`, the long-lived VPC, database, filestore and Solr
index, and `compute/`, everything that runs on top of them, which can be
destroyed between uses without touching the data.

## Current scope

Phase 1, phase 2 and the completed parts of phase 3: a VPC, a load balancer
serving HTTPS at the site's domain (`wfh.fairdom-seek.org` for staging) in
front of SEEK web instances,
autoscaled on CPU, and a worker instance, in EC2 Auto Scaling groups, MySQL on
RDS, Redis on ElastiCache, the filestore and a shared file cache on EFS, and
Solr on its own instance, with its index on a separate volume, reached by a
private DNS name. Every connection between them is encrypted, and the data
lives in a stack of its own. It needs no IAM permissions beyond the
`Developer` permission set, and has been deployed and torn down successfully.

## Phase 2

- **Completed:** HTTPS, first with a self-signed certificate, now with an ACM
  certificate for the site's domain (see phase 4)
- **Completed:** A private DNS name for Solr
- **Completed:** Front-end autoscaling
- **Completed:** A shared file cache across web instances
- **Completed:** A Redis auth token
- **Completed:** Solr isolated in its own security group
- **Completed:** Every connection between components encrypted: MySQL and
  Solr over TLS, and the load balancer to the web instances over HTTPS
- **Completed:** A durable Solr index that survives instance replacement;
  snapshots still need an IAM role from the Hub

## Phase 3

- **Completed:** Separate stacks for data and compute, so the compute can be
  taken down without touching the database, filestore or Solr index
- **Completed:** Pulumi `protect` on the database, EFS and the Solr volume, so
  a `destroy` fails rather than deleting them (`protectData`, off for
  staging)
- **Completed for the web tier:** Instance sizes from load testing: four Puma
  workers per `t3.large` (configurable), and its CPU the limit; the worker,
  Solr and database still to review, and the Solr JVM memory to make
  configurable
- **Completed:** Autoscaling on requests per instance and on slow responses as
  well as CPU, with a health check that tolerates overload, the newest
  instance removed first, and requests routed to the least busy instance
- Faster scaling out: instances that boot faster (a prepared image or a warm
  pool), a minimum of two web instances, and load shedding under overload
- A vCPU quota above 16, to allow more than six web instances
- Scaling on Puma's own fullness or memory (needs CloudWatch permissions from
  the Hub)

## Phase 4 (post-staging)

- **Completed:** A real domain, `wfh.fairdom-seek.org` for staging, delegated
  to Route 53, with a certificate from ACM
- Database and EFS backups
- Container logs in CloudWatch
- Higher availability for production: a NAT gateway per AZ, Multi-AZ RDS, a
  Redis replica
- Email delivery, so SEEK can send account, notification and error emails

## Getting started

Prerequisites: the [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/),
the AWS CLI v2 with its `session-manager-plugin`, and AWS credentials for the
`biofair-mc-workflow-hub` account from `aws configure sso` (SSO region
`eu-north-1`, default region `eu-west-2`). The SEEK and Solr images named in
`compute/Pulumi.staging.yaml` must already be pushed to Docker Hub.

Both stacks use the same passphrase, and it must come from the environment:
the compute stack reads the data stack's outputs, and cannot prompt for its
passphrase.

```console
export AWS_PROFILE=workflowhub   # the profile name you chose in aws configure sso
export PULUMI_CONFIG_PASSPHRASE_FILE=~/.workflowhub-passphrase   # a file only you can read
pulumi login --local

cd data
pulumi stack init staging
pulumi config set --secret dbPassword "$(openssl rand -hex 16)"
# First the site's DNS zone alone, then delegate the domain to it
pulumi up --target 'urn:pulumi:staging::biofair-mc-workflow-hub-data::aws:route53/zone:Zone::publicZone'
pulumi stack output nameServers
# ...add these as NS records for the domain at the parent domain's DNS host
# (e.g. host "wfh" in fairdom-seek.org), wait for them to resolve, then:
pulumi up

cd ../compute
pulumi stack init staging
pulumi up
```

SEEK is then at `pulumi stack output url` (in `compute/`), a few minutes after
`up` finishes.
`stack init` and `config set --secret` add your stacks' salts and the
encrypted password to the `Pulumi.staging.yaml` files; don't commit them.

To take down the compute and keep the data, in `compute/`:

```console
pulumi destroy
```

and `pulumi up` there brings it back. To remove everything, including the
data, destroy the compute stack first, then the data stack:

```console
cd compute && pulumi destroy && pulumi stack rm --preserve-config staging
cd ../data && pulumi destroy && pulumi stack rm --preserve-config staging
```
