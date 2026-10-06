# WorkflowHub on AWS: Pulumi architecture

Diagrams of what the Pulumi project in
[`infra/biofair-mc-workflow-hub/`](../infra/biofair-mc-workflow-hub/) deploys,
and how the project is put together. For the reasoning behind the design, see
[`SEEK-pulumi-handover.md`](SEEK-pulumi-handover.md); for deploy steps, see the
project's [README](../infra/biofair-mc-workflow-hub/README.md).

Not yet deployed or previewed against AWS.

## Phase 1 on this branch: one EC2 instance

The program currently deploys a single instance running SEEK's
`docker-compose.yml`, not the managed-services design the rest of this
document shows. See the project
[README](../infra/biofair-mc-workflow-hub/README.md).

```mermaid
flowchart LR
    you(["Developer"])
    gh[("GitHub<br/>seek4science/seek")]
    hub[("Docker Hub")]

    subgraph vpc["VPC"]
        subgraph ec2["EC2 instance in a private subnet<br/>Ubuntu 24.04, no inbound"]
            seek["SEEK<br/>:3000"]
            workers["Workers"]
            db[("MySQL")]
            redis[("Redis")]
            solr["Solr"]
        end
        nat["NAT Gateway<br/>public subnet"]
    end

    you -- "SSM port forward to 3000" --> seek
    seek --> db
    seek --> redis
    seek --> solr
    workers --> db
    workers --> redis
    workers --> solr
    ec2 -. "first boot: clone, image pulls" .-> nat
    nat -.-> gh
    nat -.-> hub
```

The sections below describe the managed-services design, a candidate for
phase 2.

## Services overview

The services and how they connect. Services with a thick border run as
multiple containers.

```mermaid
flowchart LR
    users(["Users"])
    alb["Load balancer"]
    web["Front-end<br/>2-8 containers, autoscaled"]
    workers["Workers<br/>1 container, can be raised"]
    solr["Solr<br/>1 container"]
    db[("MySQL<br/>app data + job queue")]
    redis[("Redis<br/>cache + sessions")]
    files[("Shared filestore<br/>uploads + file cache")]

    users --> alb --> web
    web --> db
    web --> redis
    web --> solr
    web --> files
    workers --> db
    workers --> redis
    workers --> solr
    workers --> files

    classDef multi stroke-width:4px
    class web multi
```

| Service | Runs as | Containers |
|---|---|---|
| Front-end | ECS Fargate service | 2-8, scaled on CPU |
| Workers | ECS Fargate service | 1, can be raised (`workerCount`) |
| Solr | Docker on a dedicated EC2 instance | 1 |
| MySQL | RDS, managed | n/a, single instance |
| Redis | ElastiCache, managed | n/a, single node |
| Shared filestore | EFS, managed | n/a, mounted by every front-end and worker container |

## Runtime architecture

How a request reaches SEEK, and which services each part of SEEK depends on.

```mermaid
flowchart TB
    users(["Users"])
    hub[("Docker Hub<br/>fairdom/seek:pulumi<br/>fairdom/seek-solr:pulumi")]

    subgraph aws["AWS account: biofair-mc-workflow-hub (eu-west-2)"]
        dns["Route 53 public record<br/>domainName"]
        alb["Application Load Balancer<br/>HTTPS 443, HTTP 80 redirects"]

        subgraph ecs["ECS cluster (Fargate)"]
            web["web service<br/>2-8 tasks, autoscaled on CPU<br/>nginx :3000 to Puma"]
            workers["workers service<br/>1 task<br/>Solid Queue + supercronic"]
        end

        subgraph solrbox["Solr EC2 instance"]
            solr["seek-solr container<br/>:8983"]
        end
        privdns["Route 53 private zone<br/>solr.seek.internal"]

        rds[("RDS MySQL 8.4<br/>app data + job queue")]
        redis[("ElastiCache Redis 7.1, TLS<br/>cache, sessions, throttling")]
        efs[("EFS<br/>/filestore and /cache<br/>access points")]
        ebs[("EBS gp3 volume<br/>Solr index, protected")]
        secrets["Secrets Manager<br/>DB password, Redis token"]
        dlm["DLM<br/>nightly snapshots, 7 kept"]
    end

    users --> dns --> alb --> web
    web --> rds
    web --> redis
    web --> efs
    web -- "solr.seek.internal" --> solr
    workers --> rds
    workers --> redis
    workers --> efs
    workers --> solr
    privdns -.- solr
    solr --- ebs
    dlm -.-> ebs
    secrets -. "injected at task start" .-> web
    secrets -. "injected at task start" .-> workers
    hub -. "pulled via NAT" .-> web
    hub -. "pulled via NAT" .-> workers
    hub -. "pulled via NAT" .-> solr
```

| docker-compose service | AWS resource |
|---|---|
| `seek` | ECS Fargate service `web` behind the ALB |
| `seek_workers` | ECS Fargate service `workers`, no ingress |
| `db` | RDS MySQL 8.4 |
| `redis_store` | ElastiCache Redis replication group |
| `solr` | EC2 instance running `fairdom/seek-solr`, index on a standalone EBS volume |
| `seek-filestore`, `seek-cache` volumes | One EFS filesystem, two access points |

## Network and security groups

Two Availability Zones, each with a public and a private subnet. Only the load
balancer and the NAT Gateway sit in public subnets.

```mermaid
flowchart TB
    internet(["Internet"])

    subgraph vpc["VPC: vpcCidr, e.g. 10.30.0.0/16"]
        subgraph public["Public subnets, AZ a and b"]
            alb["ALB<br/>SG: albSg"]
            nat["NAT Gateway<br/>single, AZ a"]
        end

        subgraph appsg["Private subnets, SG: appSg"]
            tasks["web and worker tasks<br/>ALB reaches web tasks only"]
            solr["Solr instance<br/>AZ a, same AZ as its EBS volume"]
        end

        subgraph datasg["Private subnets, SG: dataSg"]
            rds[("RDS")]
            redis[("ElastiCache")]
            efs[("EFS mount targets<br/>one per AZ")]
        end
    end

    internet -- "443, 80" --> alb
    alb -- "3000" --> tasks
    tasks -- "8983" --> solr
    tasks -- "3306" --> rds
    tasks -- "6379" --> redis
    tasks -- "2049 NFS" --> efs
    tasks & solr -. "outbound" .-> nat
    nat -. "image pulls etc." .-> internet
```

| Security group | Inbound |
|---|---|
| `albSg` | 443 and 80 from anywhere |
| `appSg` | 3000 from `albSg`; 8983 from `appSg` itself |
| `dataSg` | 3306, 6379 and 2049 from `appSg` only |

No security group opens port 22. Administrative access is through SSM Session
Manager: the Solr instance uses the account's existing `ssm-instance-profile`,
and ECS Exec is planned for the Fargate tasks.

## Project structure and deployment flow

What lives where in the SEEK repository, and how it becomes a running stack.

```mermaid
flowchart LR
    subgraph repo["SEEK repository, pulumi branch"]
        dockerfile["Dockerfile"]
        solrdf["solr/Dockerfile<br/>+ solr/seek/conf"]
        subgraph proj["infra/biofair-mc-workflow-hub/"]
            program["Pulumi.yaml<br/>config schema, variables,<br/>resources, outputs"]
            stack["Pulumi.staging.yaml<br/>stack config, committed,<br/>secrets encrypted"]
            readme["README.md"]
        end
        handover["docs/SEEK-pulumi-handover.md<br/>design decisions"]
    end

    dockerhub[("Docker Hub")]
    state[("Pulumi state backend<br/>not yet chosen")]
    awsacct["AWS account<br/>biofair-mc-workflow-hub"]

    dockerfile -- "docker build + push, by hand" --> dockerhub
    solrdf -- "docker build + push, by hand" --> dockerhub
    program --> up{{"pulumi up<br/>stack: staging"}}
    stack --> up
    up <--> state
    up -- "creates and updates resources" --> awsacct
    dockerhub -- "images pulled at runtime" --> awsacct
    handover -. "explains" .-> program
```

### Inside `Pulumi.yaml`

The program is a single Pulumi YAML file in four sections:

| Section | Contents |
|---|---|
| `config` | Per-stack settings: `environment`, `vpcCidr`, domain and certificate, image tags, task counts, instance sizes, and the `dbPassword`/`redisAuthToken` secrets |
| `variables` | Values shared between resources: the `namePrefix` (`biofair-mc-workflow-hub-<environment>`), the SEEK container environment and secrets, EFS volumes and mounts, and lookups of the Solr subnet, the AMI and the SSM instance profile |
| `resources` | Networking, security groups, secrets, RDS, ElastiCache, EFS, ECS cluster, load balancer and DNS, Solr instance and volume, snapshot policy, the two ECS services, and frontend autoscaling |
| `outputs` | Site URL, database and Redis endpoints, EFS ID, cluster name, Solr private IP |

Every resource is tagged `Environment` and `ManagedBy: pulumi` through the AWS
provider's `defaultTags` in the stack config.
