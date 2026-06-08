#!/usr/bin/env bash
# Configure KUBECONFIG pour le cluster kind local (Mac + Jenkins).
# Usage : eval "$(./scripts/k8s-env.sh)"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path

if ! k8s_ensure_cluster_access; then
    echo "echo 'Cluster inaccessible — ./scripts/minikube-setup.sh'" >&2
    exit 1
fi

echo "export KUBECONFIG=${KUBECONFIG}"
echo "# context: $(kubectl config current-context 2>/dev/null || echo unknown)"
