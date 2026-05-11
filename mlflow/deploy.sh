#!/bin/bash
# Deploy MLflow tracking server to Kubernetes.
# Run from your laptop (requires kubectl access to the cluster).
#
# Usage: ./mlflow/deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MLFLOW_NS="mlflow"

echo "==> Creating mlflow namespace"
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

echo "==> Deploying MLflow tracking server"
kubectl apply -f "$SCRIPT_DIR/mlflow.yaml"

echo "==> Waiting for deployment to be ready..."
kubectl rollout status deployment/mlflow -n "$MLFLOW_NS" --timeout=120s

echo ""
echo "=== MLflow Access ==="
echo ""
echo "From your laptop (port-forward):"
echo "  kubectl port-forward svc/mlflow -n $MLFLOW_NS 5000:5000"
echo "  Open http://localhost:5000"
echo ""
echo "From Slurm jobs (internal K8s DNS):"
echo "  export MLFLOW_TRACKING_URI=http://mlflow.mlflow.svc.cluster.local:5000"
echo ""
echo "Teardown with:"
echo "  ./mlflow/teardown.sh"
