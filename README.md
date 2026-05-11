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
