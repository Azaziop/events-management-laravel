#!/usr/bin/env bash
# Prépare Minikube pour EventApp (étape 5 — Kubernetes local).
set -euo pipefail

command -v minikube >/dev/null 2>&1 || {
    echo "Minikube introuvable. Installez-le : https://minikube.sigs.k8s.io/docs/start/"
    exit 1
}

command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl introuvable."
    exit 1
}

command -v helm >/dev/null 2>&1 || {
    echo "Helm introuvable. Installez-le : brew install helm"
    exit 1
}

echo "=== Démarrage Minikube ==="
if ! minikube status >/dev/null 2>&1; then
    minikube start --driver=docker --cpus=4 --memory=4096
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
