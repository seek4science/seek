# SEEK / WorkflowHub on AWS with Pulumi — design handover

Output of a design conversation. Self-contained: everything needed to continue
the work is in this file, including the full program source.

**Status:** sketch, not deployed. Nothing here has been run against AWS. Open
questions 4.1–4.4 have been answered from the SEEK codebase (section 4) and the
program updated to match; 4.5–4.7 remain. The one SEEK code change required
before `pulumi up` (Redis TLS, section 5.1) has been made.

**Source of truth for the app:** [`seek4science/seek`](https://github.com/seek4science/seek),
specifically `docker-compose.yml` on `main`.

---

## 1. What this is and why Pulumi

[Pulumi](https://www.pulumi.com/) is infrastructure-as-code using general-purpose
languages (TypeScript, Python, Go, C#, Java) plus YAML and HCL. Open source, with
an optional hosted backend for state and secrets.

The key framing: **a docker-compose file and a Pulumi program do not overlap.**
Compose describes containers on one host. Pulumi describes the cloud resources
underneath. Adopting Pulumi is not "convert the compose file", it is "decide
where these containers run."

Three levels of ambition were considered:

1. Pulumi provisions a VM; compose runs unchanged on it. Smallest jump, often the
   right stopping point for a single institutional deployment.
2. Pulumi for cloud resources, a Rails-native tool (Kamal, Capistrano) for app deploys.
3. Decompose into managed services. **This is what the program below does.**

**Caveat for a Rails team:** Pulumi has no Ruby SDK. Infrastructure lives in YAML
here, or Python if it outgrows YAML. Worth weighing against Terraform/OpenTofu,
which have broader institutional familiarity.

---

## 2. Architecture

```
Users
  |
  v
Application Load Balancer          (public subnets, HTTPS, ACM cert)
  |
  v
seek web          2-8 Fargate tasks, autoscaled on CPU
seek workers      1+ Fargate tasks (Solid Queue + supercronic)
solr              1 EC2 instance  (NOT Fargate - see decision 3.6)
  |
  v
RDS MySQL 8.4     app data + job queue
ElastiCache Redis cache, sessions, throttle counters (no durable data)
EFS               filestore + tmp/cache, two access points
EBS               solr index, standalone volume, nightly snapshots
```

### Compose service mapping

| Compose service | Becomes |
|---|---|
| `db` (mysql:8.4) | RDS MySQL 8.4, private subnets, encrypted, 14-day backups |
| `redis_store` (redis:8.6) | ElastiCache replication group, TLS + auth token, `allkeys-lru`. Cache, sessions, throttle counters |
| `solr` (solr:9.10.1) | Dedicated EC2 instance, persistent EBS volume, nightly DLM snapshots |
| `seek` | Fargate service behind an ALB, autoscaled 2→8 |
| `seek_workers` | Fargate service, no ingress, one task by default |
| `seek-filestore` | EFS access point at `/filestore` |
| `seek-cache` | EFS access point at `/cache` on the same filesystem |

---

## 3. Decision log

Each of these was argued through and in several cases reversed. The reasoning
matters more than the conclusion — if a premise turns out wrong, revisit.

### 3.1 Containers, not native processes

`seek` is Puma and `seek_workers` is a set of Ruby processes; both could run as
systemd units on a VM, which would make the shared filesystem problem disappear
entirely (same host = local disk). Rejected because it means owning SEEK's whole
dependency stack (Ruby, ImageMagick, document conversion, native extensions) in
parallel with upstream's supported Docker path.

### 3.2 Frontend scales horizontally; filestore must therefore be shared

Multiple web tasks each need to see the same uploads, so EFS with ReadWriteMany
semantics is unavoidable. This is the single constraint that shapes most of the
rest of the design.

### 3.3 `tmp/cache` on EFS — reversed, now shared

Initially moved off EFS on the assumption it was conventional Rails fragment
caching (many small reads/writes, EFS's worst case). **Corrected:** SEEK sends
most caching to Redis; `tmp/cache` holds a small number of largish files above a
configurable size threshold. Few-large-files is EFS's *good* case, and sharing it
means an expensive generated file produced by one task is servable by any other
rather than regenerated per task. So it is a second access point on the same
filesystem.

### 3.4 Job queue is Solid Queue, in the same database

SEEK on `main` uses Solid Queue, not Delayed Job. Jobs live in the **same**
MySQL database as application data. Consequences:

- Redis holds no durable application data, but it is **not** cache only: it
  also holds user sessions (`config/initializers/session_store.rb`) and the
  Rack::Attack throttle counters. Losing it logs everyone out and resets
  throttling; nothing is lost. ElastiCache's snapshot-based durability is
  therefore fine and the `appendonly yes` in compose need not be reproduced.
  Note that `allkeys-lru` can evict sessions under memory pressure, as it
  already can in compose — size `redisNodeType` so that it does not.
- Queue state is covered by RDS backups and PITR, consistently with app data.
- Solid Queue polls with `FOR UPDATE SKIP LOCKED` against the same instance that
  serves user queries. Unlikely to matter at SEEK's traffic, but size the
  instance on measurement and watch `max_connections` as the frontend autoscales.

### 3.5 Workers can scale — reversed

Originally fixed at one task on the grounds that supercronic, in the same
container, would fire every cron job twice. **Corrected:** all periodic
application work is in `config/recurring.yml`, run by Solid Queue's scheduler,
which is safe across multiple supervisors (recurring executions are guarded by a
unique index). `docker/seek.crontab` holds only a reaper for long-running
LibreOffice processes, and that acts on processes *inside its own container* —
so every worker task needs its own copy, and running it per task is correct
rather than a duplication. `workerCount` can therefore be raised if job
throughput demands it. Keep it at 1 until it does; each worker task holds its
own pool of MySQL connections.

### 3.6 Solr is NOT on Fargate — reversed

Originally an ECS-managed EBS volume. **That is wrong:** such a volume is created
with the task and destroyed with it, with no reattach path, so every deploy would
hand Solr an empty disk. SEEK's reindex is slow and grows with the corpus, so the
index must outlive both container and instance.

Now: a dedicated EC2 instance with a **standalone** `aws:ebs:Volume` (a separate
resource, so replacing the instance reattaches the same disk), `protect: true`,
and nightly DLM snapshots.

EFS was rejected for the index. Lucene relies on file locking and `MMapDirectory`;
NFS locking is unreliable and the failure mode is a corrupt index discovered
later, not a clean error at mount time. Performance is secondary but also poor —
EFS read latency is low-single-digit milliseconds against sub-millisecond gp3,
metadata operations each cost a round trip, and Lucene's query path is many small
random reads. EFS also bills per operation, the inverse of the `tmp/cache` case.

**SolrCloud was considered and deferred.** Replication (not sharding) is what SEEK
would want, but honest HA needs a three-node ZooKeeper quorum alongside two Solr
nodes — five machines for one institution's search index. It also changes cores to
collections and moves configuration into ZooKeeper, and whether SEEK's Solr client
supports that is an open question (Sunspot, if used, is single-node oriented).
Proportionate next step instead: put the single instance in an autoscaling group
of size one so failure triggers automatic replacement and volume reattachment.

### 3.7 Cloud Map dropped

Service discovery was only needed to register changing task IPs. With Solr on a
fixed instance there is nothing dynamic left, so a plain Route 53 private hosted
zone resolves `solr.seek.internal`. Fewer moving parts, same name.

### 3.8 Migrations are not a deploy race — but first-run setup is

`docker/entrypoint.sh` does **not** run migrations. SEEK treats schema changes as
a deliberate `docker/upgrade.sh` step in a temporary container, and the FAIRDOM
docs note upgrades must be applied one version at a time. So rolling multiple
frontend tasks does not race on the schema, and a deploy pipeline cannot jump
between arbitrary image tags.

It **does** run `rake db:setup` when the database looks empty (see 4.4). That
is a race if several web tasks start against a fresh RDS instance, so the
first deploy must create the schema before the web service runs more than one
task.

### 3.9 Fargate over EC2 for the app tier

Fargate gives each task its own ENI (`awsvpc` mode), which is why the program
attaches security groups to services and uses `targetType: ip`. Trade-offs:
sizing is a fixed CPU/memory matrix; image pull happens on every task start with
no warm cache, which dominates autoscaling responsiveness given SEEK's large
image (consider SOCI lazy loading if slow); no SSH, so enable ECS Exec before you
need it; Graviton is ~20% cheaper but needs an arm64 image build.

Fargate costs more per unit compute than EC2. For steady institutional load, an
ECS capacity provider on reserved EC2 would be cheaper. Switching later is not a
rewrite — task definitions, load balancer, EFS mounts and databases are unaffected.

---

## 4. Open questions

4.1–4.4 were answered by reading the SEEK repo; the program in section 8
reflects the answers. 4.5–4.7 remain open.

**4.1 Database and Redis hostnames — RESOLVED; Redis needs a SEEK change.**

- *MySQL:* fully overridable. `docker/database.docker.mysql.yml` (copied to
  `config/database.yml` at boot) reads `MYSQL_HOST`, `MYSQL_DATABASE`,
  `MYSQL_USER` and `MYSQL_PASSWORD`. `db` is only a fallback when `MYSQL_HOST`
  is unset (`docker/shared_functions.sh`, `set_default_mysql_host`). No alias
  record or `DATABASE_URL` needed.
- *Redis:* `Seek::RedisConfig.url` (`lib/seek/redis_config.rb`) is the single
  source of the connection URL for the cache, settings cache, sessions and
  Rack::Attack. It reads `REDIS_HOST` and `REDIS_PASSWORD`, but the **port is
  hardcoded to 6379** (so `REDIS_PORT` is ignored and has been removed from the
  program) and the **scheme is hardcoded to `redis://`**. ElastiCache with
  `transitEncryptionEnabled` accepts only TLS, and an `authToken` requires
  transit encryption, so SEEK cannot connect as sketched. See SEEK change 5.1.
- *MySQL TLS:* the image writes `[client] skip-ssl` into
  `/etc/mysql/conf.d/disable-ssl.cnf`, so the entrypoint's `mysqladmin` and
  `mysql` readiness checks never use TLS. RDS for MySQL 8.4 is believed to
  default `require_secure_transport` to ON (verify against the 8.4 parameter
  group defaults); if so those checks fail, with the consequences in 4.4. The
  program now sets `require_secure_transport = 0` in `dbParams`, acceptable
  since RDS is reachable only from `appSg` inside private subnets. SEEK change
  5.2 is the alternative.

**4.2 EFS access point uid/gid — RESOLVED: 33:33, not 1000:1000.** The runtime
image ends with `USER www-data`, and in the Debian base image
(`ruby:3.3-slim-trixie`) `www-data` is uid/gid 33. Both access points are now
`33:33`. Taken from Debian's static uid allocation; confirm with
`docker run --rm fairdom/seek:<tag> id` before deploying.

**4.3 `/seek/public/assets` — RESOLVED: safe to scale.** Assets are precompiled
in the Dockerfile builder stage (`rake assets:precompile`), so the anonymous
volume is populated from the image and every task on the same tag serves
identical digests. The one exception: `entrypoint.sh` recompiles at boot if
`RAILS_RELATIVE_URL_ROOT` is set. **Keep it unset** (this deployment serves from
the domain root) and `webCount > 1` is fine.

**4.4 What `entrypoint.sh` does at boot — RESOLVED.** On every web task, in order:

1. `check_mysql`: waits for `mysqladmin ping`, then if
   `mysql -e "desc $MYSQL_DATABASE.users"` fails, **runs `rake db:setup`**.
   - On a fresh RDS instance, several web tasks starting together all run
     `db:setup` concurrently. **First deploy: run the one-off setup task (or
     start with `webCount: 1`) before scaling out.**
   - The same branch fires if the check fails for any *other* reason (TLS
     refusal, wrong password, DNS). Rails' protected-environment check should
     stop `db:setup` loading the schema over an existing production database,
     but the result is a confusing boot failure. See SEEK change 5.3.
2. `start_search`: because `SOLR_PORT` is set, copies
   `docker/seek_local_search_enabled.rb` into `config/initializers`. Local to
   the container; concurrency-safe.
3. Renders `docker/nginx.conf.template` and later runs **nginx on :3000, proxying
   to Puma on :2000** inside the container. ALB target port 3000 is correct;
   nginx serves `public/` and `/assets` directly.
4. `rake sitemap:create &`: each task regenerates the sitemap into its own
   container filesystem. Redundant across tasks but harmless.
5. Puma (`docker/puma.rb`): `workers` defaults to `Concurrent.processor_count`,
   1 thread each. On Fargate this can report the host's CPUs rather than the
   task's allocation, so the program now sets `PUMA_WORKERS_NUM` explicitly.
   Request concurrency per task equals this number.
6. Workers and supercronic are skipped because `NO_ENTRYPOINT_WORKERS` is set.

The worker task (`docker/start_workers.sh`) waits for the database rather than
creating it (`wait_for_database`), so it is not part of the first-run race. Its
crontab (`docker/seek.crontab`) contains only the LibreOffice (`soffice.bin`)
reaper; all periodic application work is in `config/recurring.yml` under Solid
Queue. This reverses decision 3.5 — see there.

**4.5 Solr configset.** Compose bind-mounts `./solr/seek/conf`. Needs baking into
a derived image pushed to ECR; `solrImage` in stack config points at it.

**4.6 EBS device naming.** The Solr user data assumes the volume appears at
`/dev/nvme1n1`; Nitro renames attached devices, so `/dev/sdf` in the attachment is
advisory. The script waits for the device and formats only if unformatted (which
is what makes reattachment safe), but confirm on first boot.

**4.7 Provider version checks.** `awsx:ecs:FargateService` argument shapes and the
`aws:dlm:LifecyclePolicy` schema should be checked against the pinned provider
version rather than trusted from this sketch.

---

## 5. SEEK code changes

Everything else in this document is infrastructure: Pulumi program, stack
config, or one-off operational steps. These are the items that need changes to
the SEEK repository itself. Only 5.1 blocks deployment.

| # | Change | Required? | Alternative without a SEEK change |
|---|---|---|---|
| 5.1 | Redis TLS support in `Seek::RedisConfig` — **DONE** | **Yes**, as the program stands | Disable `transitEncryptionEnabled` and drop `authToken` on ElastiCache |
| 5.2 | Allow TLS for the entrypoint's MySQL client checks | No | `require_secure_transport = 0` in `dbParams` (done) |
| 5.3 | `check_mysql` distinguishes "cannot connect" from "empty database" | No, hardening | Run first-run setup as a one-off task; watch boot logs |
| 5.4 | Build and publish a derived Solr image from `solr/seek/conf` | No, convenience | Build it outside the repo and push to ECR by hand |

**5.1 Redis TLS (required) — DONE.** `Seek::RedisConfig.url`
(`lib/seek/redis_config.rb`) now uses the `rediss://` scheme when `REDIS_TLS`
is `1`, `true` or `yes` (case-insensitive), and `redis://` otherwise, so
compose deployments are unaffected. Every Redis consumer (cache store,
settings cache, session store, Rack::Attack) goes through this method, so it is
the whole change; cases added to `test/unit/redis_config_test.rb`. Verified
that both client libraries treat `rediss://` as TLS: `redis-client` (behind
`RedisCacheStore`) and `redis-store` 1.11 (behind the `:redis_store` session
store, including its `/0/session` path form). ElastiCache's certificate is
publicly trusted, so no CA bundle is needed. The program sets `REDIS_TLS=1`.

**5.2 MySQL client TLS (optional).** The Dockerfile writes `[client] skip-ssl`
to `/etc/mysql/conf.d/disable-ssl.cnf`, so `mysqladmin`/`mysql` in
`docker/shared_functions.sh` cannot talk to a server that requires TLS.
Making this conditional (e.g. on an env var at boot) would let RDS keep
`require_secure_transport` on. Also worth checking whether the `mysql2`
connection Rails itself makes negotiates TLS by default with the bundled
client library; if not, `database.docker.mysql.yml` would need an `ssl_mode`
setting too.

**5.3 Safer first-run detection (optional).** `check_mysql` treats any failure
of `desc $MYSQL_DATABASE.users` as "database is empty" and runs `rake db:setup`.
Checking connectivity first (a plain authenticated `SELECT 1`) and only then
the table would turn misconfiguration into a clear error rather than an
attempted schema load. Benefits compose deployments too.

**5.4 Derived Solr image (optional).** Open question 4.5: the configset lives
in `solr/seek/conf` and compose bind-mounts it. A small `solr/Dockerfile`
(`FROM solr:9.10.1`, `COPY` the configset) built alongside the SEEK image in
`.github/workflows/docker-image.yml` would version the configset with the code
that depends on it, and give other cloud deployments the same image.

---

## 6. Why pure YAML, and when to switch to Python

Scaling the frontend is a runtime property (`desiredCount` plus an autoscaling
target), not a code-generation problem, so it costs three YAML blocks rather than
a loop. `fn::invoke` handles lookups (subnet AZ, current AMI), so YAML is not
limited to static values.

The constraint is that Pulumi YAML has **no iteration and no conditionals**. It
shows in exactly two places here:

- EFS mount targets, written once per AZ. (The VPC avoids this by using
  `awsx:ec2:Vpc`, which iterates internally.)
- `webEnv` and `workerEnv` duplicate their common entries, because YAML cannot
  concatenate sequences — there is no equivalent of compose's `<<: *seek_base_env`
  plus additions.

Neither justifies a real language yet. Switch to Python when you want conditional
infrastructure across environments, want to generate container definitions from
`docker-compose.yml` so the two cannot drift, or want to publish this as a
reusable component other SEEK sites instantiate. `pulumi convert --language python`
is mechanical.

**Gotcha discovered during drafting:** `securityGroups: [${sg.id}]` is invalid
YAML — `{` opens a flow mapping inside a flow sequence. Must be
`securityGroups: ["${sg.id}"]`. Easy to write, and the parse error points
elsewhere.

---

## 7. Suggested next steps for Claude Code

1. ~~Answer open questions 4.1–4.4 by reading the SEEK repo.~~ Done; see
   section 4. Confirm the www-data uid (4.2) and the RDS 8.4
   `require_secure_transport` default (4.1) when convenient.
2. ~~Make SEEK change 5.1 (Redis TLS).~~ Done; needs a SEEK image built from
   a commit that includes it.
3. `pulumi preview` against a throwaway stack and fix provider-schema drift.
4. Build the derived Solr image with the configset baked in; push to ECR
   (SEEK change 5.4 if done in-repo).
5. Add the one-off task definitions for first-run setup and `docker/upgrade.sh`.
   First-run setup must complete before the web service scales past one task
   (4.4).
6. Add ECS Exec (`enableExecuteCommand`) before it is needed.
7. Consider the single-instance autoscaling group for Solr (decision 3.6).
8. Split persistent resources (RDS, EFS, EBS) into their own stack so an app
   deploy structurally cannot destroy state.

---

## 8. Program source

Two files. Place in a directory, `pulumi stack init`, set secrets, deploy.

### `Pulumi.yaml`

```yaml
name: seek
runtime: yaml
description: >
  SEEK / WorkflowHub on AWS. Frontend and workers run as ECS Fargate services,
  MySQL on RDS, Redis on ElastiCache, filestore on EFS, Solr on its own EC2
  instance with a persistent EBS volume.
  Mirrors the service topology of seek4science/seek docker-compose.yml.

# ---------------------------------------------------------------------------
# Configuration. Set per-stack in Pulumi.<stack>.yaml.
# ---------------------------------------------------------------------------
config:
  domainName:
    type: string
    description: Public hostname, e.g. workflowhub.example.ac.uk
  certificateArn:
    type: string
    description: ACM certificate ARN in this region covering domainName
  hostedZoneId:
    type: string
    description: Route 53 zone to create the A record in
  seekImage:
    type: string
    default: fairdom/seek:main
  solrImage:
    type: string
    default: solr:9.10.1
  webCount:
    type: integer
    default: 2
    description: >
      Baseline number of frontend tasks. Use 1 for the very first deploy
      against an empty database: each web task runs `rake db:setup` at boot
      if the schema is missing, and several doing so at once race.
  webCountMax:
    type: integer
    default: 8
  workerCount:
    type: integer
    default: 1
    description: >
      Safe to raise if job throughput demands it. Solid Queue is safe across
      several supervisors, and supercronic only reaps LibreOffice processes
      inside its own container, so each task should run its own copy.
  pumaWorkers:
    type: string
    default: "2"
    description: >
      Puma worker processes per web task (1 thread each, so this is the
      task's request concurrency). Set explicitly because docker/puma.rb
      otherwise uses the processor count, which on Fargate may reflect the
      host rather than the task. Size against task memory on measurement.
  dbInstanceClass:
    type: string
    default: db.t4g.medium
  dbAllocatedStorage:
    type: integer
    default: 100
  redisNodeType:
    type: string
    default: cache.t4g.small
  solrInstanceType:
    type: string
    default: t3.medium
    description: >
      amd64 by default, since the derived Solr image may not have an arm64
      build. Switch to t4g.medium for ~20% off if it does.
  solrDataSizeGb:
    type: integer
    default: 100
  dbName:
    type: string
    default: seek_production
  dbUser:
    type: string
    default: seek
  dbPassword:
    type: string
    secret: true
  redisAuthToken:
    type: string
    secret: true

# ---------------------------------------------------------------------------
# Shared values. This is the YAML equivalent of the `x-shared: seek_base_env`
# anchor block in docker-compose.yml.
# ---------------------------------------------------------------------------
variables:
  solrHost: solr.seek.internal

  # The EBS volume and the instance must sit in the same AZ, so look up the AZ
  # of the subnet the instance goes into rather than hardcoding one.
  solrSubnet:
    fn::invoke:
      function: aws:ec2:getSubnet
      arguments:
        id: ${vpc.privateSubnetIds[0]}

  al2023:
    fn::invoke:
      function: aws:ec2:getAmi
      arguments:
        mostRecent: true
        owners: ["amazon"]
        filters:
          - name: name
            values: ["al2023-ami-2023.*-x86_64"]

  # The two services need almost the same environment but differ in a couple
  # of variables, and Pulumi YAML cannot concatenate lists -- there is no
  # equivalent of compose's `<<: *seek_base_env` plus additions for a
  # sequence. So both lists are written out. This is the only real friction
  # from staying in YAML, and is the first thing that would improve if this
  # were ever converted to Python.
  #
  # Connection settings: MYSQL_* are read by docker/database.docker.mysql.yml
  # and docker/shared_functions.sh; REDIS_HOST and REDIS_PASSWORD by
  # Seek::RedisConfig (lib/seek/redis_config.rb), which fixes the port at
  # 6379, so there is no REDIS_PORT. REDIS_TLS selects rediss://, which
  # ElastiCache below requires; it needs a SEEK image that includes handover
  # change 5.1.
  webEnv:
    - name: RAILS_ENV
      value: production
    - name: RAILS_LOG_LEVEL
      value: info
    - name: SOLR_HOST
      value: ${solrHost}
    - name: SOLR_PORT
      value: "8983"
    - name: MYSQL_HOST
      value: ${db.address}
    - name: MYSQL_DATABASE
      value: ${dbName}
    - name: MYSQL_USER
      value: ${dbUser}
    - name: REDIS_HOST
      value: ${redis.primaryEndpointAddress}
    - name: REDIS_TLS
      value: "1"
    - name: PUMA_WORKERS_NUM
      value: ${pumaWorkers}
    # As in compose: the web tasks must not also spawn queue workers.
    - name: NO_ENTRYPOINT_WORKERS
      value: "1"

  workerEnv:
    - name: RAILS_ENV
      value: production
    - name: RAILS_LOG_LEVEL
      value: info
    - name: SOLR_HOST
      value: ${solrHost}
    - name: SOLR_PORT
      value: "8983"
    - name: MYSQL_HOST
      value: ${db.address}
    - name: MYSQL_DATABASE
      value: ${dbName}
    - name: MYSQL_USER
      value: ${dbUser}
    - name: REDIS_HOST
      value: ${redis.primaryEndpointAddress}
    - name: REDIS_TLS
      value: "1"
    - name: QUIET_SUPERCRONIC
      value: "1"

  seekSecrets:
    - name: MYSQL_PASSWORD
      valueFrom: ${dbSecret.arn}
    - name: REDIS_PASSWORD
      valueFrom: ${redisSecret.arn}

  # Two shared volumes, one EFS filesystem, an access point each.
  #
  # filestore is the obvious one: every web and worker task must see the same
  # uploaded files.
  #
  # tmp/cache is shared too. It holds a small number of largish generated files
  # (the size threshold is configurable) rather than the many-small-objects
  # traffic that makes NFS painful, and most SEEK caching goes to Redis anyway.
  # So the access pattern suits EFS elastic throughput well, and sharing it
  # means an expensive generated file produced by one task can be served by
  # any other rather than regenerated per task.
  appVolumes:
    - name: filestore
      efsVolumeConfiguration:
        fileSystemId: ${sharedFs.id}
        transitEncryption: ENABLED
        authorizationConfig:
          accessPointId: ${filestoreAccessPoint.id}
          iam: ENABLED
    - name: cache
      efsVolumeConfiguration:
        fileSystemId: ${sharedFs.id}
        transitEncryption: ENABLED
        authorizationConfig:
          accessPointId: ${cacheAccessPoint.id}
          iam: ENABLED

  appMounts:
    - sourceVolume: filestore
      containerPath: /seek/filestore
      readOnly: false
    - sourceVolume: cache
      containerPath: /seek/tmp/cache
      readOnly: false

resources:
  # -------------------------------------------------------------------------
  # Networking
  #
  # awsx:ec2:Vpc is used deliberately. Pulumi YAML has no loops, so writing
  # subnets, route tables and NAT gateways per AZ by hand would be ~20 near
  # identical blocks. The component does the iteration internally.
  # -------------------------------------------------------------------------
  vpc:
    type: awsx:ec2:Vpc
    properties:
      cidrBlock: "10.0.0.0/16"
      numberOfAvailabilityZones: 2
      natGateways:
        strategy: Single # Use OnePerAz for production HA; costs roughly 2x.
      tags:
        Project: seek

  albSg:
    type: aws:ec2:SecurityGroup
    properties:
      vpcId: ${vpc.vpcId}
      description: Public ingress to the load balancer
      ingress:
        - protocol: tcp
          fromPort: 443
          toPort: 443
          cidrBlocks: ["0.0.0.0/0"]
        - protocol: tcp
          fromPort: 80
          toPort: 80
          cidrBlocks: ["0.0.0.0/0"]
      egress:
        - protocol: "-1"
          fromPort: 0
          toPort: 0
          cidrBlocks: ["0.0.0.0/0"]

  # One SG for all application tasks (web, workers, solr). They need to reach
  # each other, and the data stores admit this SG specifically.
  appSg:
    type: aws:ec2:SecurityGroup
    properties:
      vpcId: ${vpc.vpcId}
      description: SEEK application tasks
      egress:
        - protocol: "-1"
          fromPort: 0
          toPort: 0
          cidrBlocks: ["0.0.0.0/0"]

  appFromAlb:
    type: aws:ec2:SecurityGroupRule
    properties:
      type: ingress
      securityGroupId: ${appSg.id}
      sourceSecurityGroupId: ${albSg.id}
      protocol: tcp
      fromPort: 3000
      toPort: 3000

  # Solr is reached by web and workers on 8983, from within the same SG.
  appToSolr:
    type: aws:ec2:SecurityGroupRule
    properties:
      type: ingress
      securityGroupId: ${appSg.id}
      sourceSecurityGroupId: ${appSg.id}
      protocol: tcp
      fromPort: 8983
      toPort: 8983

  dataSg:
    type: aws:ec2:SecurityGroup
    properties:
      vpcId: ${vpc.vpcId}
      description: RDS, ElastiCache and EFS -- reachable only from app tasks
      ingress:
        - protocol: tcp
          fromPort: 3306
          toPort: 3306
          securityGroups: ["${appSg.id}"]
        - protocol: tcp
          fromPort: 6379
          toPort: 6379
          securityGroups: ["${appSg.id}"]
        - protocol: tcp
          fromPort: 2049 # NFS for EFS
          toPort: 2049
          securityGroups: ["${appSg.id}"]
      egress:
        - protocol: "-1"
          fromPort: 0
          toPort: 0
          cidrBlocks: ["0.0.0.0/0"]

  # -------------------------------------------------------------------------
  # Secrets
  # -------------------------------------------------------------------------
  dbSecret:
    type: aws:secretsmanager:Secret
    properties:
      name: seek/db-password
      recoveryWindowInDays: 7

  dbSecretValue:
    type: aws:secretsmanager:SecretVersion
    properties:
      secretId: ${dbSecret.id}
      secretString: ${dbPassword}

  redisSecret:
    type: aws:secretsmanager:Secret
    properties:
      name: seek/redis-auth-token
      recoveryWindowInDays: 7

  redisSecretValue:
    type: aws:secretsmanager:SecretVersion
    properties:
      secretId: ${redisSecret.id}
      secretString: ${redisAuthToken}

  # -------------------------------------------------------------------------
  # MySQL -- replaces the `db` service
  # -------------------------------------------------------------------------
  dbSubnets:
    type: aws:rds:SubnetGroup
    properties:
      subnetIds: ${vpc.privateSubnetIds}

  dbParams:
    type: aws:rds:ParameterGroup
    properties:
      family: mysql8.4
      # Matches the compose command flags on the mysql service.
      parameters:
        - name: character_set_server
          value: utf8mb4
        - name: collation_server
          value: utf8mb4_unicode_ci
        # The SEEK image configures its mysql client with `skip-ssl`, so the
        # entrypoint's readiness checks cannot connect if TLS is required
        # (handover 4.1). RDS is reachable only from appSg in private subnets.
        # Drop this if SEEK change 5.2 lands.
        - name: require_secure_transport
          value: "0"

  db:
    type: aws:rds:Instance
    properties:
      engine: mysql
      engineVersion: "8.4"
      instanceClass: ${dbInstanceClass}
      allocatedStorage: ${dbAllocatedStorage}
      maxAllocatedStorage: 500 # storage autoscaling
      dbName: ${dbName}
      username: ${dbUser}
      password: ${dbPassword}
      dbSubnetGroupName: ${dbSubnets.name}
      vpcSecurityGroupIds: ["${dataSg.id}"]
      parameterGroupName: ${dbParams.name}
      storageEncrypted: true
      multiAz: false # true for production HA
      backupRetentionPeriod: 14
      deletionProtection: true
      skipFinalSnapshot: false
      finalSnapshotIdentifier: seek-final
      applyImmediately: false

  # -------------------------------------------------------------------------
  # Redis -- replaces the `redis_store` service
  #
  # Cache, sessions and Rack::Attack throttle counters. SEEK uses Solid
  # Queue, so the job queue lives in MySQL and nothing here is durable
  # application data; losing it logs users out but loses nothing. The
  # `appendonly yes` in the compose file is therefore not worth reproducing,
  # and ElastiCache's snapshot-based durability is sufficient. allkeys-lru is
  # carried over from compose; size the node so it does not evict sessions.
  #
  # transitEncryptionEnabled means TLS-only connections; SEEK connects over
  # TLS when REDIS_TLS is set (handover change 5.1).
  # -------------------------------------------------------------------------
  redisSubnets:
    type: aws:elasticache:SubnetGroup
    properties:
      subnetIds: ${vpc.privateSubnetIds}

  redisParams:
    type: aws:elasticache:ParameterGroup
    properties:
      family: redis7
      parameters:
        - name: maxmemory-policy
          value: allkeys-lru

  redis:
    type: aws:elasticache:ReplicationGroup
    properties:
      description: SEEK Rails cache
      engine: redis
      engineVersion: "7.1"
      nodeType: ${redisNodeType}
      numCacheClusters: 1 # 2 with automaticFailoverEnabled for HA
      port: 6379
      parameterGroupName: ${redisParams.name}
      subnetGroupName: ${redisSubnets.name}
      securityGroupIds: ["${dataSg.id}"]
      atRestEncryptionEnabled: true
      transitEncryptionEnabled: true
      authToken: ${redisAuthToken}
      snapshotRetentionLimit: 7

  # -------------------------------------------------------------------------
  # EFS -- replaces the `seek-filestore` and `seek-cache` external volumes
  #
  # One filesystem, two access points. Sharing a filesystem means a single
  # throughput pool and a single backup policy; the access points keep the two
  # trees separate and independently owned.
  #
  # This is the only place the lack of loops in Pulumi YAML actually shows:
  # one mount target per AZ, written out longhand. With two AZs that is two
  # blocks. Add a third if you raise numberOfAvailabilityZones above.
  # -------------------------------------------------------------------------
  sharedFs:
    type: aws:efs:FileSystem
    properties:
      encrypted: true
      throughputMode: elastic # avoids the burst-credit cliff
      lifecyclePolicies:
        - transitionToIa: AFTER_60_DAYS
        - transitionToPrimaryStorageClass: AFTER_1_ACCESS
      tags:
        Name: seek-shared

  efsMountA:
    type: aws:efs:MountTarget
    properties:
      fileSystemId: ${sharedFs.id}
      subnetId: ${vpc.privateSubnetIds[0]}
      securityGroups: ["${dataSg.id}"]

  efsMountB:
    type: aws:efs:MountTarget
    properties:
      fileSystemId: ${sharedFs.id}
      subnetId: ${vpc.privateSubnetIds[1]}
      securityGroups: ["${dataSg.id}"]

  # The access point pins ownership. Get the uid/gid wrong and SEEK starts
  # cleanly then silently fails to write uploads, which is the single most
  # common way this setup breaks. The fairdom/seek image runs as www-data,
  # uid/gid 33 in its Debian base image (handover 4.2).
  filestoreAccessPoint:
    type: aws:efs:AccessPoint
    properties:
      fileSystemId: ${sharedFs.id}
      posixUser:
        uid: 33
        gid: 33
      rootDirectory:
        path: /filestore
        creationInfo:
          ownerUid: 33
          ownerGid: 33
          permissions: "0755"

  # Cache files are regenerable, so no lifecycle transition to IA here -- an
  # IA read incurs a retrieval charge, and these get re-read while warm.
  cacheAccessPoint:
    type: aws:efs:AccessPoint
    properties:
      fileSystemId: ${sharedFs.id}
      posixUser:
        uid: 33
        gid: 33
      rootDirectory:
        path: /cache
        creationInfo:
          ownerUid: 33
          ownerGid: 33
          permissions: "0755"

  efsBackup:
    type: aws:efs:BackupPolicy
    properties:
      fileSystemId: ${sharedFs.id}
      backupPolicy:
        status: ENABLED

  # -------------------------------------------------------------------------
  # Cluster, service discovery, load balancer
  # -------------------------------------------------------------------------
  cluster:
    type: aws:ecs:Cluster
    properties:
      name: seek
      settings:
        - name: containerInsights
          value: enabled

  # Solr now runs on a fixed instance rather than a task, so a plain private
  # hosted zone replaces Cloud Map -- there is nothing dynamic left to register.
  internalZone:
    type: aws:route53:Zone
    properties:
      name: seek.internal
      comment: Internal name resolution for the SEEK stack
      vpcs:
        - vpcId: ${vpc.vpcId}

  solrRecord:
    type: aws:route53:Record
    properties:
      zoneId: ${internalZone.zoneId}
      name: ${solrHost}
      type: A
      ttl: 60
      records:
        - ${solrInstance.privateIp}

  alb:
    type: awsx:lb:ApplicationLoadBalancer
    properties:
      subnetIds: ${vpc.publicSubnetIds}
      securityGroups: ["${albSg.id}"]
      listeners:
        - port: 80
          protocol: HTTP
          defaultActions:
            - type: redirect
              redirect:
                port: "443"
                protocol: HTTPS
                statusCode: HTTP_301
        - port: 443
          protocol: HTTPS
          certificateArn: ${certificateArn}
      defaultTargetGroup:
        port: 3000
        protocol: HTTP
        targetType: ip
        vpcId: ${vpc.vpcId}
        deregistrationDelay: 30
        healthCheck:
          path: /up # the healthcheck endpoint used in docker-compose.yml
          interval: 30
          timeout: 5
          healthyThreshold: 2
          unhealthyThreshold: 5
          matcher: "200"
      # Sticky sessions are usually unnecessary for Rails with a shared session
      # store, but enable here if SEEK turns out to keep per-instance state.
      # defaultTargetGroup.stickiness: { type: lb_cookie, enabled: true }

  dnsRecord:
    type: aws:route53:Record
    properties:
      zoneId: ${hostedZoneId}
      name: ${domainName}
      type: A
      aliases:
        - name: ${alb.loadBalancer.dnsName}
          zoneId: ${alb.loadBalancer.zoneId}
          evaluateTargetHealth: true

  # -------------------------------------------------------------------------
  # Solr -- replaces the `solr` service
  #
  # NOT a Fargate task. An ECS-managed EBS volume is created and destroyed with
  # the task, so every deploy would hand Solr an empty disk and trigger a full
  # reindex. That reindex grows with the corpus, so the index has to outlive
  # both the container and the instance.
  #
  # Hence: a standalone EBS volume, attached to a dedicated instance. The volume
  # is a separate resource from the instance, so replacing the instance
  # reattaches the same disk rather than starting from nothing. Snapshots via
  # DLM below give a restore path if the volume itself is lost.
  #
  # The compose file bind-mounts ./solr/seek/conf from the repo; off a single
  # host that has to be baked into a derived image. solrImage points at it.
  # -------------------------------------------------------------------------
  solrData:
    type: aws:ebs:Volume
    properties:
      availabilityZone: ${solrSubnet.availabilityZone}
      size: ${solrDataSizeGb}
      type: gp3
      encrypted: true
      tags:
        Name: seek-solr-data
        Snapshot: seek-solr
    options:
      protect: true

  solrRole:
    type: aws:iam:Role
    properties:
      assumeRolePolicy: |
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Principal": { "Service": "ec2.amazonaws.com" },
            "Action": "sts:AssumeRole"
          }]
        }
      managedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  solrProfile:
    type: aws:iam:InstanceProfile
    properties:
      role: ${solrRole.name}

  solrInstance:
    type: aws:ec2:Instance
    properties:
      ami: ${al2023.id}
      instanceType: ${solrInstanceType}
      subnetId: ${vpc.privateSubnetIds[0]}
      vpcSecurityGroupIds: ["${appSg.id}"]
      iamInstanceProfile: ${solrProfile.name}
      tags:
        Name: seek-solr
      userData: |
        #!/bin/bash
        set -euo pipefail
        dnf install -y docker
        systemctl enable --now docker

        DEV=/dev/nvme1n1
        for i in $(seq 1 60); do [ -b "$DEV" ] && break; sleep 2; done

        if ! blkid "$DEV"; then mkfs.ext4 -m0 "$DEV"; fi
        mkdir -p /var/solr
        grep -q "$DEV" /etc/fstab || echo "$DEV /var/solr ext4 defaults,nofail 0 2" >> /etc/fstab
        mount -a
        chown -R 8983:8983 /var/solr

        docker run -d --restart always --name solr \
          -p 8983:8983 \
          -v /var/solr:/var/solr \
          -e SOLR_JAVA_MEM="-Xms512m -Xmx1024m" \
          ${solrImage} \
          solr-precreate seek /opt/solr/server/solr/configsets/seek_config

  solrAttach:
    type: aws:ec2:VolumeAttachment
    properties:
      deviceName: /dev/sdf
      volumeId: ${solrData.id}
      instanceId: ${solrInstance.id}
      # Do not let Pulumi yank the disk out from under a running Solr.
      stopInstanceBeforeDetaching: true

  # Nightly snapshots of the index volume. The index is technically derivable
  # from MySQL, but a reindex is slow enough that restoring a snapshot is the
  # faster recovery path.
  dlmRole:
    type: aws:iam:Role
    properties:
      assumeRolePolicy: |
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Principal": { "Service": "dlm.amazonaws.com" },
            "Action": "sts:AssumeRole"
          }]
        }
      managedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole

  solrSnapshots:
    type: aws:dlm:LifecyclePolicy
    properties:
      description: Nightly snapshots of the SEEK Solr index
      executionRoleArn: ${dlmRole.arn}
      state: ENABLED
      policyDetails:
        resourceTypes: ["VOLUME"]
        targetTags:
          Snapshot: seek-solr
        schedules:
          - name: nightly
            createRule:
              interval: 24
              intervalUnit: HOURS
              times: ["03:00"]
            retainRule:
              count: 7
            copyTags: true

  # SEEK frontend -- replaces the `seek` service
  #
  # This is where horizontal scaling lives. desiredCount is just a number;
  # going from 2 tasks to 8 is a config change, not more infrastructure.
  # NO_ENTRYPOINT_WORKERS mirrors the compose setting so the web tasks do not
  # also spawn job workers.
  # -------------------------------------------------------------------------
  web:
    type: awsx:ecs:FargateService
    properties:
      cluster: ${cluster.arn}
      desiredCount: ${webCount}
      networkConfiguration:
        subnets: ${vpc.privateSubnetIds}
        securityGroups: ["${appSg.id}"]
      taskDefinitionArgs:
        cpu: "1024"
        memory: "2048"
        volumes: ${appVolumes}
        containers:
          seek:
            name: seek
            image: ${seekImage}
            essential: true
            command: ["docker/entrypoint.sh"]
            portMappings:
              - containerPort: 3000
                targetGroup: ${alb.defaultTargetGroup}
            environment: ${webEnv}
            secrets: ${seekSecrets}
            mountPoints: ${appMounts}
            healthCheck:
              command:
                ["CMD-SHELL", "curl -f http://localhost:3000/up || exit 1"]
              interval: 30
              timeout: 5
              retries: 5
              startPeriod: 60

  # -------------------------------------------------------------------------
  # Solid Queue workers -- replaces the `seek_workers` service
  #
  # No target group, no ingress. Jobs live in the same database as the rest of
  # the application, so queue state is covered by RDS backups and PITR along
  # with everything else. Can be scaled via workerCount (handover 3.5).
  # -------------------------------------------------------------------------
  workers:
    type: awsx:ecs:FargateService
    properties:
      cluster: ${cluster.arn}
      desiredCount: ${workerCount}
      networkConfiguration:
        subnets: ${vpc.privateSubnetIds}
        securityGroups: ["${appSg.id}"]
      taskDefinitionArgs:
        cpu: "1024"
        memory: "2048"
        volumes: ${appVolumes}
        containers:
          seek-workers:
            name: seek-workers
            image: ${seekImage}
            essential: true
            command: ["docker/start_workers.sh"]
            environment: ${workerEnv}
            secrets: ${seekSecrets}
            mountPoints: ${appMounts}
            healthCheck:
              command: ["CMD", "bash", "script/check_worker_pids.sh"]
              interval: 30
              timeout: 10
              retries: 5
              startPeriod: 60

  # -------------------------------------------------------------------------
  # Autoscaling for the frontend
  # -------------------------------------------------------------------------
  webScaleTarget:
    type: aws:appautoscaling:Target
    properties:
      serviceNamespace: ecs
      scalableDimension: ecs:service:DesiredCount
      resourceId: service/${cluster.name}/${web.service.name}
      minCapacity: ${webCount}
      maxCapacity: ${webCountMax}

  webScalePolicy:
    type: aws:appautoscaling:Policy
    properties:
      policyType: TargetTrackingScaling
      serviceNamespace: ${webScaleTarget.serviceNamespace}
      scalableDimension: ${webScaleTarget.scalableDimension}
      resourceId: ${webScaleTarget.resourceId}
      targetTrackingScalingPolicyConfiguration:
        targetValue: 65
        predefinedMetricSpecification:
          predefinedMetricType: ECSServiceAverageCPUUtilization
        scaleInCooldown: 300
        scaleOutCooldown: 60

outputs:
  url: https://${domainName}
  databaseEndpoint: ${db.address}
  redisEndpoint: ${redis.primaryEndpointAddress}
  sharedFsId: ${sharedFs.id}
  clusterName: ${cluster.name}
  solrPrivateIp: ${solrInstance.privateIp}
```

### `Pulumi.prod.yaml`

Secrets are set with `pulumi config set --secret`, never written here.

```yaml
# Example stack configuration.
# Secrets are set with `pulumi config set --secret`, not written in plaintext here.
#
#   pulumi config set --secret dbPassword
#   pulumi config set --secret redisAuthToken

config:
  aws:region: eu-west-2 # London

  seek:domainName: workflowhub.example.ac.uk
  seek:certificateArn: arn:aws:acm:eu-west-2:111122223333:certificate/REPLACE-ME
  seek:hostedZoneId: REPLACEME

  seek:seekImage: fairdom/seek:1.16.0 # pin a release rather than :main
  seek:solrImage: 111122223333.dkr.ecr.eu-west-2.amazonaws.com/seek-solr:9.10.1

  seek:webCount: "2"
  seek:webCountMax: "8"
  seek:workerCount: "1"
  seek:pumaWorkers: "2"

  seek:dbInstanceClass: db.t4g.medium
  seek:dbAllocatedStorage: "100"
  seek:redisNodeType: cache.t4g.small
```

### Deploy

```bash
pulumi stack init prod
pulumi config set --secret dbPassword
pulumi config set --secret redisAuthToken
# edit Pulumi.prod.yaml for domain, certificate, hosted zone

pulumi preview
pulumi up
```

Then once: create the schema via a one-off task against the `seek` task
definition **before** the web service runs more than one task (otherwise each
web task's entrypoint tries `rake db:setup` concurrently; see 4.4 — the
simplest route is `webCount: 1` for the first `pulumi up`, then raise it), and
run the initial Solr index. That first index is the slow
one — later deploys reattach the existing volume and do not reindex.
On subsequent SEEK releases run `docker/upgrade.sh` as a standalone task
before rolling the services, one version at a time.
