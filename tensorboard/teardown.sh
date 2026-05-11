#!/bin/bash
# Remove TensorBoard from Kubernetes.
#
# Usage: ./tensorboard/teardown.sh

set -euo pipefail

echo "==> Deleting TensorBoard deployment and service"
kubectl delete -f "$(dirname "$0")/tensorboard.yaml" --ignore-not-found

echo "==> TensorBoard removed"
