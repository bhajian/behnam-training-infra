#!/bin/bash
# Tear down MLflow from Kubernetes.
# Data on the host (/mnt/data/mlflow) is preserved.
#
# Usage: ./mlflow/teardown.sh

set -euo pipefail

MLFLOW_NS="mlflow"

echo "==> Deleting MLflow deployment and service"
kubectl delete -f "$(dirname "$0")/mlflow.yaml" --ignore-not-found

echo "==> Deleting mlflow namespace"
kubectl delete namespace "$MLFLOW_NS" --ignore-not-found

echo "==> MLflow removed (data preserved on host at /mnt/data/mlflow)"
