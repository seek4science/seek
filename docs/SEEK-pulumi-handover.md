# SEEK / WorkflowHub on AWS with Pulumi — design handover

Output of a design conversation: the reasoning behind the Pulumi program in
[`infra/biofair-mc-workflow-hub/`](../infra/biofair-mc-workflow-hub/), whose
README covers how to deploy it.

**Status:** sketch, not deployed. Nothing here has been run against AWS. Open
questions 4.1–4.4 have been answered from the SEEK codebase (section 4) and the
program updated to match; 4.5 is resolved by SEEK change 5.4; 4.6–4.7 remain. The one SEEK code change required
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
3. Decompose into managed services. **This is what the program does.**

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

4.1–4.4 were answered by reading the SEEK repo; the program reflects the
answers. 4.5 is resolved by SEEK change 5.4. 4.6–4.7 remain open.

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

**4.5 Solr configset — RESOLVED by 5.4.** Compose bind-mounts
`./solr/seek/conf`. `solr/Dockerfile` now bakes it into a derived image
(`fairdom/seek-solr`), which `solrImage` in stack config points at.

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
| 5.4 | Derived Solr image from `solr/seek/conf` — **DONE** | No, convenience | Build it outside the repo |

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

**5.4 Derived Solr image — DONE.** Open question 4.5: the configset lives in
`solr/seek/conf` and compose bind-mounts it. `solr/Dockerfile` (`FROM
solr:9.10.1`) bakes it in as `seek_config`, so the configset is versioned with
the code that depends on it. Build from the `solr` directory and push by hand
alongside `fairdom/seek`, with the same tag:

```bash
docker build -t fairdom/seek-solr:<seek-version> solr
```

The image also fixes a problem compose has today. `solr-precreate` copies the
configset only when the core does not yet exist, so on a persistent volume an
existing core keeps the configuration it was created with, and a release that
changes `solr/seek/conf` (e.g. #2690) needs a manual copy. The image's
`start-seek-solr.sh` replaces an existing core's `conf/` with the baked-in
configset on every start, then hands over to `solr-precreate`; the index data
is untouched, and the reindex in `seek:upgrade` covers changes that affect
indexing. Tested locally: a restart with a changed configset refreshed the
core's conf and kept the indexed documents. The image carries a `HEALTHCHECK`
on `/solr/seek/admin/ping`, matching compose.

`solr:9.10.1` is multi-arch, so `docker buildx build --platform
linux/amd64,linux/arm64 --push` would allow a Graviton `solrInstanceType`.

Compose and `script/start-docker-solr.sh` still bind-mount the configset and so
do not get the refresh; switching them to the image is a possible follow-up.

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

Phase 1 has been deployed; see [`pulumi-next-phase.md`](pulumi-next-phase.md)
for what the next phase needs. The list below is the original plan.

1. ~~Answer open questions 4.1–4.4 by reading the SEEK repo.~~ Done; see
   section 4. Confirm the www-data uid (4.2) and the RDS 8.4
   `require_secure_transport` default (4.1) when convenient.
2. ~~Make SEEK change 5.1 (Redis TLS).~~ Done; needs a SEEK image built from
   a commit that includes it.
3. `pulumi preview` against a throwaway stack and fix provider-schema drift.
4. Build and push `fairdom/seek-solr` (SEEK change 5.4, done) at the same tag
   as the SEEK image.
5. Add the one-off task definitions for first-run setup and `docker/upgrade.sh`.
   First-run setup must complete before the web service scales past one task
   (4.4).
6. Add ECS Exec (`enableExecuteCommand`) before it is needed.
7. Consider the single-instance autoscaling group for Solr (decision 3.6).
8. Split persistent resources (RDS, EFS, EBS) into their own stack so an app
   deploy structurally cannot destroy state.

---

## 8. Program

The program lives in
[`infra/biofair-mc-workflow-hub/`](../infra/biofair-mc-workflow-hub/), laid out
like `biofair-mc-galaxy/` in
[biofair-mc-infra](https://github.com/BioFAIRUK/biofair-mc-infra) and named after
the AWS account it targets:

- `Pulumi.yaml`: the program.
- `Pulumi.staging.yaml`: the `staging` stack's config, committed. Each
  deployer's local stack adds its salt and encrypted secrets to it, which are
  not committed.
- `README.md`: scope and getting started.
- `tech-notes.md`: how it works, setting up access, and operating the stack.

**Phase 1.** The program currently deploys a cut-down phase 1 of this design:
HTTP only at the load balancer's hostname, fixed instance counts, the Solr
index on the instance's root volume, no shared file cache,
no Redis auth token, and no EFS backups. [`pulumi-next-phase.md`](pulumi-next-phase.md)
lists what phase 2 adds back.

**Not Fargate.** On this branch the front-end and workers run as Docker
containers on EC2 instances in Auto Scaling groups, rather than as ECS Fargate
services (decision 3.9). Fargate needs IAM roles for ECS and permission to
pass them, which the `Developer` permission set does not have. The
instances use the account's existing SSM instance profile instead, and the
database password moves from Secrets Manager to SSM Parameter Store, which
that profile can read. RDS,
ElastiCache, EFS, the load balancer and Solr are unchanged.

Following biofair-mc-infra's conventions, it differs from the sketch that was
originally embedded here in these ways:

- One stack per environment; `staging` rather than `prod`, since the
  Methods Commons accounts have no production OU yet.
- Resource names are prefixed `biofair-mc-workflow-hub-<environment>`, and
  every resource is tagged `Environment` and `ManagedBy: pulumi` through the
  AWS provider's `defaultTags` in the stack config.
- The VPC CIDR is stack config (`10.30.0.0/16` for staging).
- Every instance uses the account's existing `ssm-instance-profile`, and the
  program creates no IAM roles (see "Not Fargate" above).
