# Behnam Deploy - Soperator L40s Cluster

Deploys a Slurm-on-K8s cluster with 2x L40s GPUs in eu-north1 using the Nebius Soperator.

## Deployment

```bash
# 1. Set environment variables (sensitive -- do NOT put these in tfvars)
# NEBIUS_IAM_TOKEN is used by the nebius provider; TF_VAR_iam_token by kubernetes/flux/helm providers
export NEBIUS_IAM_TOKEN=$(nebius iam get-access-token)
export TF_VAR_iam_token="$NEBIUS_IAM_TOKEN"
export TF_VAR_vpc_subnet_id=$(nebius vpc subnet list --parent-id project-e00v3cy1pr00enkn7rdbhm --format json | jq -r '.items[0].metadata.id')

# 2. Deploy
cd soperator/installations/behnam-deploy/
terraform init
terraform plan
terraform apply
```

## Teardown

```bash
terraform destroy
```

## Configuration

Key settings in `terraform.tfvars`:

| Setting | Value |
|---|---|
| Region | eu-north1 |
| Soperator | 3.0.3 (stable) |
| K8s version | 1.32 |
| Workers | 2x gpu-l40s-d / 1gpu-16vcpu-96gb |
| Login nodes | 2x cpu-d3 / 32vcpu-128gb |
| InfiniBand | Disabled (L40s uses Ethernet) |
| GPU drivers | Preinstalled (`use_preinstalled_gpu_drivers = true`) |
| Accounting | Enabled |
| public_o11y_enabled | false |
| production | false |

### Storage

#### Filestores (existing)

| Name | Size | ID |
|---|---|---|
| behnam-jail (jail) | 1 TiB | `computefilesystem-e00kr1pch5f6nb1dx7` |
| behnam-jail-data (jail submount at `/mnt/data`) | 1 TiB | `computefilesystem-e00y7vfyr9nms4w82q` |

#### Filestores (created by Terraform)

| Name | Size |
|---|---|
| soperator-behnam-controller-spool | 128 GiB |
| soperator-behnam-accounting | 512 GiB |

#### Node-local disks (per worker)

| Name | Size | Type | Mount |
|---|---|---|---|
| local-data | 1 TiB | NETWORK_SSD | `/mnt/local-data` |
| image disk | 930 GiB | NETWORK_SSD_IO_M3 | (Docker/Enroot images) |

#### NFS in K8s

| Size | Disk type | Threads |
|---|---|---|
| 930 GiB | NETWORK_SSD_IO_M3 | 32 |

### Preemptible Fallback

If no PAYG L40s capacity is available, change `preemptible = null` to `preemptible = {}` in the worker config.

---

## MLflow Tracking Server

MLflow is deployed on Kubernetes to track training experiments (loss curves, learning rates, hyperparameters, artifacts). Data is stored on a 10Gi PersistentVolumeClaim so it survives pod rescheduling.

### Deploy

```bash
cd soperator/installations/behnam-deploy/
./mlflow/deploy.sh
```

The script will:
1. Create the `mlflow` namespace
2. Create a 10Gi PVC for MLflow data (backend DB + artifacts)
3. Deploy the MLflow tracking server (ClusterIP service)

### Access the MLflow UI (from your laptop)

MLflow uses a ClusterIP service (no public IP needed). Use port-forwarding:

```bash
kubectl port-forward svc/mlflow -n mlflow 5000:5000
# Open http://localhost:5000
```

### Connect training jobs to MLflow

Slurm nodes are inside the K8s cluster, so they reach MLflow via internal DNS. This is already set in `train.sbatch`:

```bash
export MLFLOW_TRACKING_URI=http://mlflow.mlflow.svc.cluster.local:5000
```

No manual IP configuration needed — just deploy MLflow and submit your training job.

### Teardown

```bash
./mlflow/teardown.sh
```

Data on the PVC is deleted when the namespace is removed. To preserve data, back up the PVC before tearing down.

---

## TensorBoard (Torch Profiler Visualization)

TensorBoard is deployed alongside MLflow to visualize PyTorch profiler traces. It reads profiler output from the training nodes via hostPath.

### Prerequisites

- MLflow namespace must exist (deploy MLflow first)
- At least one training run with `profiler_enabled: true` in the config YAML

### Deploy

```bash
cd soperator/installations/behnam-deploy/
./tensorboard/deploy.sh
```

### Access the TensorBoard UI (from your laptop)

TensorBoard uses a ClusterIP service. Use port-forwarding:

```bash
kubectl port-forward svc/tensorboard -n mlflow 6006:6006
# Open http://localhost:6006
```

### Using the Profiler Dashboard

1. Open `http://localhost:6006` in your browser
2. Select **PYTORCH_PROFILER** from the dropdown in the top-right
3. Available views:
   - **Overview** — GPU utilization %, time breakdown, top expensive ops
   - **Operator View** — all PyTorch operators sorted by GPU/CPU time
   - **GPU Kernel View** — individual CUDA kernels, launch counts, durations
   - **Trace View** — Chrome-trace-style CPU/GPU timeline (most detailed)
   - **Memory View** — allocation timeline, peak usage, per-op memory

### Teardown

```bash
./tensorboard/teardown.sh
```
