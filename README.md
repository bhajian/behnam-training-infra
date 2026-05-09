# Behnam Deploy - Soperator L40s Cluster

Deploys a Slurm-on-K8s cluster with 2x L40s GPUs in eu-north1 using the Nebius Soperator.

## Prerequisites

- [Nebius CLI](https://docs.nebius.com/cli/install) installed and authenticated (`nebius iam whoami`)
- `yq` installed (`brew install yq`)
- `terraform` installed
- `jq` installed

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
| Workers | 2x gpu-l40s-a / 1gpu-16vcpu-64gb |
| InfiniBand | Disabled (L40s uses Ethernet) |
| public_o11y_enabled | false |
| production | false |

### Existing Filestores

| Name | ID |
|---|---|
| soperator-demo-day-jail (2 TiB) | computefilesystem-e02j5pw8f0z0rmf9gq |
| soperator-demo-day-jail-submount-data (1 TiB) | computefilesystem-e02c40yywsa2wecdp6 |
| soperator-demo-day-controller-spool (128 GiB) | computefilesystem-e02kwsfke317jevds1 |

### Preemptible Fallback

If no PAYG L40s capacity is available, change `preemptible = null` to `preemptible = {}` in the worker config.
