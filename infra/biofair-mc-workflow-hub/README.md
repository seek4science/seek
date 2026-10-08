# WorkflowHub

Pulumi component provisioning the `biofair-mc-workflow-hub` account's AWS
infrastructure for WorkflowHub, which runs SEEK. It is written in Pulumi YAML.

## Current scope

Phase 1: a VPC, an HTTP load balancer in front of SEEK web and worker
instances in EC2 Auto Scaling groups, MySQL on RDS, Redis on ElastiCache, the
filestore on EFS, and Solr on its own instance. It needs no IAM permissions
beyond the `Developer` permission set, and has been deployed and torn down
successfully.

## Getting started

Prerequisites: the [Pulumi CLI](https://www.pulumi.com/docs/iac/download-install/),
the AWS CLI v2 with its `session-manager-plugin`, and AWS credentials for the
`biofair-mc-workflow-hub` account from `aws configure sso` (SSO region
`eu-north-1`, default region `eu-west-2`). The SEEK and Solr images named in
`Pulumi.staging.yaml` must already be pushed to Docker Hub.

```console
export AWS_PROFILE=workflowhub   # the profile name you chose in aws configure sso

pulumi login --local
pulumi stack init staging
pulumi config set --secret dbPassword "$(openssl rand -hex 16)"

pulumi preview
pulumi up
```

SEEK is then at `pulumi stack output url`, a few minutes after `up` finishes.
`stack init` and `config set --secret` add your stack's salt and encrypted
password to `Pulumi.staging.yaml`; don't commit them.

To remove everything, including the data:

```console
pulumi destroy
pulumi stack rm --preserve-config staging
```
