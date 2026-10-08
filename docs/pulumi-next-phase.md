# WorkflowHub on AWS: next phase

What is needed to take the Pulumi program in
[`infra/biofair-mc-workflow-hub/`](../infra/biofair-mc-workflow-hub/) from
phase 1 to the full design in [`SEEK-pulumi-handover.md`](SEEK-pulumi-handover.md).

## Where phase 1 stands

Phase 1 is the managed-services design with the extras left out, and with the
front-end and workers as Docker containers on EC2 Auto Scaling groups rather
than ECS Fargate. It has been deployed in the `biofair-mc-workflow-hub`
account, paused and resumed with its data intact, and destroyed cleanly. It
needs no IAM permissions beyond the `Developer` permission set.

The full design, before phase 1 cut it down, is in the history at commit
`6550a42c0b`. Most items below were already written there and can be adapted
rather than written from scratch:

```console
git show 6550a42c0b:infra/biofair-mc-workflow-hub/Pulumi.yaml
```

Resource names in this document (`dnsRecord`, `solrData` and so on) refer to
that file. When bringing any of it back, keep the fixes phase 1 found: VPC
DNS hostnames, explicit lowercase names for the RDS and ElastiCache groups,
gp3 database storage, and `-sg` security group names.

## Phase 2 items

Roughly in order of value. Each says what it adds, what it needs, and anything
that blocks it.

### 1. HTTPS and a real domain

- **Adds:** an ACM certificate on a 443 listener, port 80 redirecting to it,
  and a Route 53 alias record for the domain.
- **Needs:** config for `domainName`, `certificateArn` and `hostedZoneId`; the
  `alb` listeners and `dnsRecord` from the full design; port 443 on `albSg`.
- **Blocked on:** the DNS and ACM question with the Hub: who owns the hosted
  zone, and how a certificate is issued.

### 2. Front-end autoscaling

- **Adds:** 2-8 web instances, scaled on CPU.
- **Needs:** a `webCountMax` setting, `maxSize: ${webCountMax}` on `webGroup`,
  and an `aws:autoscaling:Policy` with target tracking on
  `ASGAverageCPUUtilization`. The full design's `webScaleTarget` and
  `webScalePolicy` were written for ECS and do not carry over directly.
- **Consider:** new instances take several minutes to boot and pull the SEEK
  image, so scale out early (a lower CPU target) rather than late. Item 5
  becomes worthwhile once there is more than one web instance.

### 3. Durable Solr index

- **Adds:** an index that survives the Solr instance being replaced, so a
  replacement does not mean a full reindex (handover 3.6).
- **Needs:** the full design's `solrData` (a standalone, protected gp3
  volume in the instance's AZ), `solrAttach`, and the Solr user data that
  waits for the device, formats it only if empty, and mounts it at
  `/var/solr`. The `ignoreChanges: ["ami"]` on the instance can then go.
- **Snapshots:** the full design's nightly DLM snapshots (`dlmRole`,
  `solrSnapshots`) need an IAM role, which `Developer` cannot create. Either
  ask the Hub for the role, or rely on a reindex as the recovery path.
- **Check:** the device name on the current instance types and AMI (handover
  4.6).

### 4. Private DNS name for Solr

- **Adds:** `solr.seek.internal` instead of the instance's IP in the SEEK
  environment, so replacing Solr does not need the web and worker instances
  rolled.
- **Needs:** the full design's `internalZone` and `solrRecord`, and
  `SOLR_HOST=solr.seek.internal` in `hostSetup`.

### 5. Shared file cache

- **Adds:** a `tmp/cache` shared between web instances, so a large generated
  file is not regenerated per instance (handover 3.3).
- **Needs:** the full design's `cacheAccessPoint`; a second mount in
  `hostSetup` (e.g. `/mnt/cache`); and `-v /mnt/cache:/seek/tmp/cache` on the
  web and worker `docker run`.

### 6. Redis auth token

- **Adds:** a password on Redis, on top of TLS and the security group.
- **Needs:** an `authToken` on the replication group, the token in Parameter
  Store as a SecureString (as the database password is), read in `hostSetup`
  and written as `REDIS_PASSWORD` to `/etc/seek.env`. Generate it in the
  program rather than as stack config (see below).

### 7. Backups

- **Adds:** EFS backups (the full design's `efsBackup`) to go with RDS's
  automated backups, which phase 1 already has (14 days).
- **Check:** EFS automatic backups use AWS Backup and its service role; test
  whether `Developer` can enable them before relying on it.

### 8. Container logs in CloudWatch

- **Adds:** Rails, Puma and worker logs in the console, kept after an
  instance is replaced.
- **Needs:** CloudWatch Logs permissions for the instances, and either the
  `awslogs` Docker log driver or the CloudWatch agent. The existing SSM
  instance profile does not include them, so this needs the Hub: extra
  permissions on that profile, or a second profile the program can use.

### 9. Higher availability

For production rather than staging: a NAT gateway per AZ (`strategy:
OnePerAz`), Multi-AZ RDS, an ElastiCache replica with automatic failover, and
Solr in an Auto Scaling group of one. Each roughly doubles the cost of that
part.

## Cross-cutting work

- **Shared Pulumi state backend.** S3 or Pulumi Cloud, agreed with
  biofair-mc-infra, before anyone other than the first deployer manages the
  stack.
- **Generate secrets in the program.** Use `random:RandomPassword` for the
  database password (and the Redis token), letters and digits only, so the
  stack config holds no secrets and nobody chooses one by hand.
- **Separate stacks for data and compute** (handover next steps). RDS, EFS
  and the Solr volume in one stack, everything else in another, so a
  teardown cannot touch the data and the compute can be destroyed between
  trials at near-zero cost.
- **VPC ownership.** Whether the Hub provides networking, in which case the
  program's VPC is replaced by lookups.
- **A production stack** once a production account exists, with deletion
  protection and final snapshots on (the defaults).

## Fargate (deferred)

The `pulumi-fargate-phase-1` branch has phase 1 on ECS Fargate instead of
Auto Scaling groups, with the fixes its preview found, including the
execution role's read access to the database secret. It needs:

- two IAM roles trusted by `ecs-tasks.amazonaws.com`: an execution role with
  the AWS-managed `AmazonECSTaskExecutionRolePolicy` plus
  `secretsmanager:GetSecretValue` on the database secret, and a task role;
- permission for the deployer to pass those roles to ECS on every deploy
  that changes a task definition.

`Developer` cannot create IAM roles or pass them to ECS, so this needs the
roles and that permission from the Hub, or a permission set that has them.
The program would then take the role ARNs as config rather than creating
them. That branch also predates phase 1's VPC DNS hostnames and gp3 fixes.
