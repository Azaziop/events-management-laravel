#!/usr/bin/env bash
# Prépare le cluster Kubernetes local (Minikube ou kind selon l'environnement).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path

if ! command -v kubectl >/dev/null 2>&1 || ! command -v helm >/dev/null 2>&1; then
    k8s_log_line "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl introuvable après installation."
    exit 1
}

command -v helm >/dev/null 2>&1 || {
    echo "Helm introuvable après installation."
    exit 1
}

if k8s_should_use_kind; then
    k8s_log_line "=== Jenkins-in-Docker détecté — cluster kind (Minikube incompatible) ==="
    kind_setup_cluster
else
    if ! command -v minikube >/dev/null 2>&1; then
        install_k8s_tools_if_missing
    fi
    command -v minikube >/dev/null 2>&1 || {
        echo "Minikube introuvable après installation."
        exit 1
    }
    minikube_setup_cluster
fi

echo ""
k8s_log_line "Cluster prêt. Prochaine étape : IMAGE_TAG=<tag> ./scripts/k8s-deploy.sh"
