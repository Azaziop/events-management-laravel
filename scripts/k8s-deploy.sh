#!/usr/bin/env bash
# Déploie EventApp sur Minikube via Helm.
set -euo pipefail

RELEASE="${HELM_RELEASE:-eventapp}"
NAMESPACE="${K8S_NAMESPACE:-default}"
CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../helm/events-management" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-azaziop/event-management1}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG requis (ex. 23-f681023)}"
VALUES_FILE="${HELM_VALUES:-${CHART_DIR}/values.minikube.yaml}"

command -v helm >/dev/null 2>&1 || { echo "Helm introuvable"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl introuvable"; exit 1; }

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo "=== Chargement de l'image dans Minikube : ${IMAGE_NAME}:${IMAGE_TAG} ==="
    if docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
        minikube image load "${IMAGE_NAME}:${IMAGE_TAG}"
    else
        echo "Image locale absente, Helm tentera un pull depuis le registry."
    fi
fi

echo "=== Déploiement Helm : ${RELEASE} (namespace: ${NAMESPACE}) ==="
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f "${VALUES_FILE}" \
    --set image.repository="${IMAGE_NAME}" \
    --set image.tag="${IMAGE_TAG}" \
    --wait --timeout 5m

echo ""
helm get notes "${RELEASE}" --namespace "${NAMESPACE}" 2>/dev/null || true

echo ""
echo "=== Statut des pods ==="
kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE}" -o wide

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo ""
    echo "URL :"
    minikube service "${RELEASE}-events-management" -n "${NAMESPACE}" --url 2>/dev/null \
        || minikube service "${RELEASE}" -n "${NAMESPACE}" --url 2>/dev/null \
        || echo "http://$(minikube ip):30080"
fi
