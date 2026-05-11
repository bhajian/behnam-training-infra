#!/bin/bash
# Deploy TensorBoard to visualize torch profiler traces.
# Runs in the same namespace as MLflow. Deploy MLflow first.
#
# Usage: ./tensorboard/deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NS="mlflow"

if ! kubectl get namespace "$NS" &>/dev/null; then
    echo "Error: namespace '$NS' does not exist. Deploy MLflow first:"
    echo "  ./mlflow/deploy.sh"
    exit 1
fi

echo "==> Deploying TensorBoard"
kubectl apply -f "$SCRIPT_DIR/tensorboard.yaml"

echo "==> Waiting for deployment to be ready..."
kubectl rollout status deployment/tensorboard -n "$NS" --timeout=120s

echo ""
echo "=== TensorBoard Access ==="
echo ""
echo "From your laptop (port-forward):"
echo "  kubectl port-forward svc/tensorboard -n $NS 6006:6006"
echo "  Open http://localhost:6006"
echo ""
echo "To profile a training run, set in your config YAML:"
echo "  profiler_enabled: true"
echo ""
echo "Teardown with:"
echo "  ./tensorboard/teardown.sh"
