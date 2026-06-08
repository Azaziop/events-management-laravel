#!/usr/bin/env bash
# Prépare Minikube pour EventApp (étape 5 — Kubernetes local / Jenkins).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path

if ! command -v minikube >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1 || ! command -v helm >/dev/null 2>&1; then
    echo "=== Outils K8s absents — installation automatique ==="
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

echo "=== Démarrage Minikube (driver=docker, cpus=${MINIKUBE_CPUS}, memory=${MINIKUBE_MEMORY}Mi) ==="
if ! minikube status >/dev/null 2>&1; then
    minikube start \
        --driver=docker \
        --cpus="${MINIKUBE_CPUS}" \
        --memory="${MINIKUBE_MEMORY}" \
        --force
else
    echo "Minikube déjà démarré."
fi

echo "=== Activation des addons ==="
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

echo "=== Contexte kubectl ==="
kubectl config use-context minikube
kubectl cluster-info

echo ""
echo "Minikube prêt. Prochaine étape :"
echo "  IMAGE_TAG=<tag> ./scripts/k8s-deploy.sh"
