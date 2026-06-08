#!/usr/bin/env bash
# Déploie EventApp sur Kubernetes local (Minikube ou kind) via Helm.
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
    k8s_log_line "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

command -v helm >/dev/null 2>&1 || { echo "Helm introuvable"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl introuvable"; exit 1; }

if k8s_using_kind; then
    k8s_fix_kind_kubeconfig "$(kind_cluster_name)" || true
fi

if ! k8s_ensure_cluster_access; then
    echo "Cluster Kubernetes inaccessible."
    echo "  Lancez : ./scripts/minikube-setup.sh"
    echo "  Ou     : K8S_CLUSTER=kind ./scripts/minikube-setup.sh"
    exit 1
fi

IMAGE_PULL_POLICY="Never"
if k8s_is_ci; then
    IMAGE_PULL_POLICY="IfNotPresent"
fi

if k8s_load_image_to_cluster "${IMAGE_NAME}:${IMAGE_TAG}"; then
    if k8s_using_kind; then
        IMAGE_PULL_POLICY="IfNotPresent"
    fi
else
    k8s_log_line "Image locale absente ; pull depuis le registry (pullPolicy=${IMAGE_PULL_POLICY})."
    IMAGE_PULL_POLICY="IfNotPresent"
fi

k8s_log_line "=== Déploiement Helm : ${RELEASE} (namespace: ${NAMESPACE}) ==="
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
k8s_log_line "=== Statut des pods ==="
kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE}" -o wide

echo ""
k8s_log_line "URL : $(k8s_print_app_url "${RELEASE}" "${NAMESPACE}")"
