# Local Kubernetes Setup for SEEK

This guide covers installing the tools needed to run SEEK locally on Kubernetes.

## Prerequisites

- Docker (tested with Docker Engine 29+)
- `~/.local/bin` on your `PATH`

---

## 1. Helm

Helm is the package manager used to deploy SEEK.

```bash
curl -fsSL https://get.helm.sh/helm-v3.21.1-linux-amd64.tar.gz | tar xz -C /tmp
mv /tmp/linux-amd64/helm ~/.local/bin/helm
helm version
```

Alternatively, use the official installer (requires sudo for `/usr/local/bin`):

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## 2. kubectl

```bash
curl -Lo ~/.local/bin/kubectl \
  "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ~/.local/bin/kubectl
kubectl version --client
```

---

## 3. kind (Kubernetes IN Docker) — recommended for WSL2

kind runs Kubernetes nodes as Docker containers. It is the simplest option on Linux/WSL2.

```bash
curl -Lo ~/.local/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ~/.local/bin/kind
kind version
```

### Create a cluster

```bash
kind create cluster --name seek
```

### Delete the cluster

```bash
kind delete cluster --name seek
```

---

## 4. minikube — alternative single-node cluster

minikube is a good alternative if you need more features (built-in ingress, dashboard, etc.).

```bash
curl -Lo ~/.local/bin/minikube \
  https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x ~/.local/bin/minikube
minikube version
```

### Create a cluster

```bash
minikube start --driver=docker
```

### Enable the ingress addon (optional)

```bash
minikube addons enable ingress
```

### Get the cluster IP (for accessing services)

```bash
minikube ip
```

### Delete the cluster

```bash
minikube delete
```

---

## 5. Deploy SEEK

Once a cluster is running, deploy with the local override values:

```bash
# From the repo root
helm install seek ./helm/seek -f helm/values-local.yaml
```

Watch pods start up:

```bash
kubectl get pods -l app.kubernetes.io/instance=seek -w
```

Access the app once all pods are Ready (~3–5 minutes on first boot):

```bash
kubectl port-forward svc/seek-seek 3000:3000
# Open http://localhost:3000
```

### Tear down

```bash
helm uninstall seek
kind delete cluster --name seek   # or: minikube delete
```

---

## Notes

- **RWX storage**: The production chart uses `ReadWriteMany` PVCs for the filestore and cache. `values-local.yaml` overrides these to `ReadWriteOnce`, which works on single-node clusters (kind/minikube) since both the `seek` and `seek_workers` pods land on the same node.
- **First boot**: The `entrypoint.sh` runs `db:setup` automatically on the first start. Subsequent restarts skip this step.
- **Credentials**: Never commit real passwords. Pass them at install time: `--set mysql.auth.password=<value>`.
