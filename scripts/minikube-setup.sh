#!/usr/bin/env bash
# Prépare Minikube pour EventApp (étape 5 — Kubernetes local / Jenkins).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path

if ! command -v minikube >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1 || ! command -v helm >/dev/null 2>&1; then
    k8s_log_line "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

command -v minikube >/dev/null 2>&1 || {
    echo "Minikube introuvable après installation."
    exit 1
}

command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl introuvable après installation."
    exit 1
}

command -v helm >/dev/null 2>&1 || {
    echo "Helm introuvable après installation."
    exit 1
}

MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-2048}"
MINIKUBE_K8S_VERSION="${MINIKUBE_K8S_VERSION:-v1.30.5}"
MINIKUBE_WAIT_TIMEOUT="${MINIKUBE_WAIT_TIMEOUT:-15m}"

k8s_log_line "=== Démarrage Minikube (driver=docker, k8s=${MINIKUBE_K8S_VERSION}, cpus=${MINIKUBE_CPUS}, memory=${MINIKUBE_MEMORY}Mi) ==="

minikube_start_with_progress \
    --driver=docker \
    --cpus="${MINIKUBE_CPUS}" \
    --memory="${MINIKUBE_MEMORY}" \
    --kubernetes-version="${MINIKUBE_K8S_VERSION}" \
    --wait=all \
    --wait-timeout="${MINIKUBE_WAIT_TIMEOUT}" \
    --force

k8s_log_line "=== Activation des addons ==="
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

k8s_log_line "=== Contexte kubectl ==="
kubectl config use-context minikube
kubectl cluster-info

echo ""
k8s_log_line "Minikube prêt. Prochaine étape : IMAGE_TAG=<tag> ./scripts/k8s-deploy.sh"
