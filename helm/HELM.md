# SEEK Helm Chart

Reference documentation for `helm/seek/` — the Helm chart that deploys FAIRDOM-SEEK on Kubernetes.

---

## Chart structure

```
helm/
├── seek/                        # The Helm chart
│   ├── Chart.yaml               # Chart metadata (name, version, appVersion)
│   ├── values.yaml              # Default configuration values
│   ├── files/
│   │   └── solr/conf/           # SEEK's custom Solr configset files
│   │       ├── schema.xml
│   │       ├── solrconfig.xml
│   │       ├── managed-schema
│   │       ├── protwords.txt
│   │       ├── stopwords.txt
│   │       └── synonyms.txt
│   └── templates/
│       ├── _helpers.tpl         # Named template helpers
│       ├── NOTES.txt            # Post-install instructions
│       ├── secret.yaml          # Database credentials
│       ├── configmap-solr.yaml  # Solr config files as a ConfigMap
│       ├── pvc.yaml             # Shared PVCs (filestore, cache)
│       ├── statefulset-mysql.yaml
│       ├── statefulset-redis.yaml
│       ├── statefulset-solr.yaml
│       ├── deployment-seek.yaml
│       ├── deployment-workers.yaml
│       ├── service-mysql.yaml
│       ├── service-redis.yaml
│       ├── service-solr.yaml
│       ├── service-seek.yaml
│       └── ingress.yaml
├── values-local.yaml            # Overrides for kind/minikube local testing
└── INSTALL.md                   # Tool installation guide
```

---

## Components

The chart deploys five workloads. Each maps directly to the corresponding service in `docker-compose.yml`.

| Kubernetes resource | Kind | Image | Port |
|---|---|---|---|
| `<release>-mysql` | StatefulSet | `mysql:8.4` | 3306 |
| `<release>-redis` | StatefulSet | `redis:8.6-alpine` | 6379 |
| `<release>-solr` | StatefulSet | `solr:8.11.4` | 8983 |
| `<release>-seek` | Deployment | `fairdom/seek:main` | 3000 |
| `<release>-workers` | Deployment | `fairdom/seek:main` | — |

**MySQL, Redis, and Solr** are StatefulSets because they need stable network identities and persistent storage. Each has its own `volumeClaimTemplate`, so a PVC is provisioned per pod automatically.

**seek** (web) and **seek_workers** are Deployments. They share the same image and environment but run different entrypoints:

- `seek` runs `docker/entrypoint.sh` with `NO_ENTRYPOINT_WORKERS=1`, which starts nginx + puma but skips starting workers inside the same container.
- `seek_workers` runs `docker/start_workers.sh`, which starts delayed_job and supercronic.

Both pods mount the same `filestore` and `cache` PVCs. On first boot, the `seek` pod's entrypoint detects that the database is empty and runs `db:setup` automatically.

---

## How Solr configuration is initialised

The SEEK Solr schema (`schema.xml`, `solrconfig.xml`, etc.) is stored in `helm/seek/files/solr/conf/` and embedded in the chart as a ConfigMap (`<release>-solr-conf`).

Because Kubernetes ConfigMaps cannot represent subdirectories, the Solr StatefulSet uses an **initContainer** to assemble the full configset before Solr starts:

1. The ConfigMap is mounted at `/tmp/seek-conf/`.
2. An emptyDir volume is mounted at `/opt/solr/server/solr/configsets/seek_config/`.
3. The initContainer copies the custom conf files into `conf/` and then copies the language analysis files (`lang/`) from the Solr image's built-in `_default` configset.
4. The main Solr container starts with the entrypoint `solr-precreate seek /opt/solr/server/solr/configsets/seek_config`, which creates the `seek` core on first boot and skips it on subsequent restarts (the core data lives in the persistent `/var/solr/` PVC).

A `checksum/solr-conf` annotation on the Solr pod template ensures pods roll when the ConfigMap changes.

---

## Shared storage

Two PVCs are created outside of any StatefulSet so they can be mounted by both `seek` and `seek_workers`:

| PVC | Mount path | Default size |
|---|---|---|
| `<release>-filestore` | `/seek/filestore` | 10 Gi |
| `<release>-cache` | `/seek/tmp/cache` | 5 Gi |

In production these must use `accessMode: ReadWriteMany` because the two pods may be scheduled on different nodes. Set `seek.filestore.accessMode` and `seek.cache.accessMode` accordingly, and supply a StorageClass that supports RWX.

For single-node local clusters (kind, minikube) `ReadWriteOnce` is sufficient — both pods land on the same node, so a single-node RWO volume can be mounted by multiple pods simultaneously.

---

## Configuration reference

All values can be overridden with `--set key=value` or a `-f values.yaml` file.

### Image

| Key | Default | Description |
|---|---|---|
| `image.repository` | `fairdom/seek` | SEEK image repository |
| `image.tag` | `main` | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Kubernetes pull policy |

### seek (web)

| Key | Default | Description |
|---|---|---|
| `seek.replicaCount` | `1` | Number of web pods |
| `seek.railsEnv` | `production` | `RAILS_ENV` |
| `seek.railsLogLevel` | `info` | `RAILS_LOG_LEVEL` |
| `seek.relativeUrlRoot` | `""` | Set if serving under a URL sub-path, e.g. `/seek` |
| `seek.service.type` | `ClusterIP` | Kubernetes Service type |
| `seek.service.port` | `3000` | Service port |
| `seek.filestore.storageClass` | `""` | StorageClass for the filestore PVC |
| `seek.filestore.accessMode` | `ReadWriteMany` | PVC access mode |
| `seek.filestore.size` | `10Gi` | Filestore PVC size |
| `seek.cache.storageClass` | `""` | StorageClass for the cache PVC |
| `seek.cache.accessMode` | `ReadWriteMany` | PVC access mode |
| `seek.cache.size` | `5Gi` | Cache PVC size |
| `seek.resources` | `{}` | Pod resource requests/limits |

### workers

| Key | Default | Description |
|---|---|---|
| `workers.replicaCount` | `1` | Number of worker pods |
| `workers.quietSupercronic` | `true` | Suppresses verbose cron output (`QUIET_SUPERCRONIC=1`) |
| `workers.resources` | `{}` | Pod resource requests/limits |

### MySQL

| Key | Default | Description |
|---|---|---|
| `mysql.image.repository` | `mysql` | MySQL image |
| `mysql.image.tag` | `8.4` | MySQL version |
| `mysql.auth.rootPassword` | `seek_root` | Root password — **override in production** |
| `mysql.auth.database` | `seek_docker` | Database name |
| `mysql.auth.username` | `seek_db_user` | Application user |
| `mysql.auth.password` | `seek_db_password` | Application password — **override in production** |
| `mysql.persistence.storageClass` | `""` | StorageClass for the data PVC |
| `mysql.persistence.size` | `10Gi` | Data PVC size |
| `mysql.resources` | `{}` | Pod resource requests/limits |

### Redis

| Key | Default | Description |
|---|---|---|
| `redis.image.repository` | `redis` | Redis image |
| `redis.image.tag` | `8.6-alpine` | Redis version |
| `redis.persistence.storageClass` | `""` | StorageClass for the data PVC |
| `redis.persistence.size` | `1Gi` | Data PVC size |
| `redis.resources` | `{}` | Pod resource requests/limits |

### Solr

| Key | Default | Description |
|---|---|---|
| `solr.image.repository` | `solr` | Solr image |
| `solr.image.tag` | `8.11.4` | Solr version |
| `solr.javaMem` | `-Xms512m -Xmx1024m` | JVM heap for Solr (`SOLR_JAVA_MEM`) |
| `solr.persistence.storageClass` | `""` | StorageClass for the data PVC |
| `solr.persistence.size` | `10Gi` | Data PVC size |
| `solr.resources` | `{}` | Pod resource requests/limits |

### Ingress

| Key | Default | Description |
|---|---|---|
| `ingress.enabled` | `false` | Create an Ingress resource |
| `ingress.className` | `""` | `ingressClassName` (e.g. `nginx`, `alb`) |
| `ingress.annotations` | `{}` | Annotations passed to the Ingress |
| `ingress.hosts` | see values.yaml | List of host + path rules |
| `ingress.tls` | `[]` | TLS configuration |

---

## Deploying

```bash
# Minimal install (uses default values — do not use in production)
helm install seek ./helm/seek

# Production install with credentials overridden
helm install seek ./helm/seek \
  --set mysql.auth.rootPassword=<root-pw> \
  --set mysql.auth.password=<app-pw>

# Local testing (kind/minikube)
helm install seek ./helm/seek -f helm/values-local.yaml

# Upgrade after a values change
helm upgrade seek ./helm/seek -f my-values.yaml

# Uninstall (PVCs are NOT deleted automatically)
helm uninstall seek
```

---

## AWS (EKS) deployment

The following changes are required when deploying to AWS EKS.

### Cluster

Create an EKS cluster with the [AWS CLI or eksctl](https://eksctl.io/):

```bash
eksctl create cluster \
  --name seek \
  --region eu-west-1 \
  --nodegroup-name standard \
  --node-type m6i.xlarge \
  --nodes 2
```

### StorageClasses

EKS provides an EBS CSI driver for block storage (RWO) and an EFS CSI driver for shared storage (RWX).

**Install the EBS CSI driver** (handles MySQL, Redis, Solr PVCs):

```bash
eksctl create addon --name aws-ebs-csi-driver --cluster seek
```

**Install the EFS CSI driver** (handles the filestore and cache PVCs):

```bash
eksctl create addon --name aws-efs-csi-driver --cluster seek
```

Create an EFS file system in the AWS console (or via CLI), then create a StorageClass pointing at it:

```yaml
# efs-storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-XXXXXXXXX   # your EFS file system ID
  directoryPerms: "700"
```

```bash
kubectl apply -f efs-storageclass.yaml
```

### values-aws.yaml

```yaml
seek:
  filestore:
    storageClass: efs-sc       # EFS — supports ReadWriteMany
    accessMode: ReadWriteMany
    size: 50Gi
  cache:
    storageClass: efs-sc
    accessMode: ReadWriteMany
    size: 10Gi
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "2"

workers:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "2Gi"
      cpu: "1"

mysql:
  persistence:
    storageClass: gp3           # EBS gp3
    size: 50Gi
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"

redis:
  persistence:
    storageClass: gp3
    size: 5Gi

solr:
  javaMem: "-Xms1g -Xmx2g"
  persistence:
    storageClass: gp3
    size: 20Gi
  resources:
    requests:
      memory: "2Gi"
      cpu: "500m"
    limits:
      memory: "3Gi"

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-1:XXXXXXXXXXXX:certificate/XXXXXXXX
  hosts:
    - host: seek.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - seek.example.com
      secretName: seek-tls
```

### AWS Load Balancer Controller (for ALB ingress)

```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=seek \
  --set serviceAccount.create=true
```

### Credentials

Do not pass passwords via `--set` in production. Use AWS Secrets Manager with the [External Secrets Operator](https://external-secrets.io/) to inject them as Kubernetes Secrets, or store them in a sealed values file managed by [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets).

At minimum, override the defaults before deploying:

```bash
helm install seek ./helm/seek \
  -f helm/values-aws.yaml \
  --set mysql.auth.rootPassword="$(aws secretsmanager get-secret-value --secret-id seek/mysql-root --query SecretString --output text)" \
  --set mysql.auth.password="$(aws secretsmanager get-secret-value --secret-id seek/mysql-app --query SecretString --output text)"
```

### Managed services (optional but recommended for production)

The chart bundles MySQL, Redis, and Solr as in-cluster StatefulSets. For production it is worth replacing them with managed AWS services:

| Component | AWS replacement | Benefit |
|---|---|---|
| MySQL | Amazon RDS (MySQL 8.4) | Automated backups, Multi-AZ failover |
| Redis | Amazon ElastiCache (Redis 7) | Managed failover, encryption at rest |
| Solr | — | No AWS equivalent; keep in-cluster |

To use RDS instead of the in-cluster MySQL, disable the StatefulSet by setting `mysql.enabled: false` (requires a small chart extension) and point the connection at your RDS endpoint via:

```bash
--set mysql.auth.host=seek.xxxxxxxxx.eu-west-1.rds.amazonaws.com
```

This requires adding `mysql.auth.host` to the chart's `_helpers.tpl` `seek.mysql.host` template. The same pattern applies for ElastiCache.
