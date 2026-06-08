#!/usr/bin/env bash
# Déploie EventApp sur Minikube via Helm.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path

RELEASE="${HELM_RELEASE:-eventapp}"
NAMESPACE="${K8S_NAMESPACE:-default}"
CHART_DIR="$(cd "${SCRIPT_DIR}/../helm/events-management" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-azaziop/event-management1}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG requis (ex. 23-f681023)}"
VALUES_FILE="${HELM_VALUES:-${CHART_DIR}/values.minikube.yaml}"

if ! command -v helm >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    echo "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

command -v helm >/dev/null 2>&1 || { echo "Helm introuvable"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl introuvable"; exit 1; }

IMAGE_PULL_POLICY="Never"
if k8s_is_ci; then
    IMAGE_PULL_POLICY="IfNotPresent"
fi

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo "=== Chargement de l'image dans Minikube : ${IMAGE_NAME}:${IMAGE_TAG} ==="
    if docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
        minikube image load "${IMAGE_NAME}:${IMAGE_TAG}" || {
            echo "minikube image load a échoué ; pull depuis le registry (pullPolicy=${IMAGE_PULL_POLICY})."
            IMAGE_PULL_POLICY="IfNotPresent"
        }
    else
        echo "Image locale absente ; pull depuis le registry (pullPolicy=${IMAGE_PULL_POLICY})."
        IMAGE_PULL_POLICY="IfNotPresent"
    fi
fi

echo "=== Déploiement Helm : ${RELEASE} (namespace: ${NAMESPACE}) ==="
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f "${VALUES_FILE}" \
    --set image.repository="${IMAGE_NAME}" \
    --set image.tag="${IMAGE_TAG}" \
    --set image.pullPolicy="${IMAGE_PULL_POLICY}" \
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
