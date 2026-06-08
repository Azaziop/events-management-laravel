#!/usr/bin/env bash
# Déploie la stack monitoring K8s : Prometheus + Grafana + Loki + Promtail.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="$(cd "${SCRIPT_DIR}/../helm/monitoring" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path
NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
GRAFANA_NODE_PORT="${GRAFANA_NODE_PORT:-30300}"

if ! command -v helm >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    k8s_log_line "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

if k8s_using_kind; then
    k8s_fix_kind_kubeconfig "$(kind_cluster_name)" || true
fi

kubectl cluster-info >/dev/null 2>&1 || {
    echo "Cluster Kubernetes inaccessible. Lancez d'abord ./scripts/minikube-setup.sh"
    exit 1
}

k8s_log_line "=== Ajout des dépôts Helm (prometheus-community, grafana) ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

k8s_log_line "=== Déploiement Loki (logs) ==="
helm upgrade --install loki grafana/loki \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f "${MONITORING_DIR}/loki-values.yaml" \
    --wait --timeout 5m

k8s_log_line "=== Déploiement Promtail (collecte logs) ==="
helm upgrade --install promtail grafana/promtail \
    --namespace "${NAMESPACE}" \
    -f "${MONITORING_DIR}/promtail-values.yaml" \
    --wait --timeout 5m

k8s_log_line "=== Déploiement kube-prometheus-stack (métriques + Grafana + alertes) ==="
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    -f "${MONITORING_DIR}/kube-prometheus-stack-values.yaml" \
    --wait --timeout 10m

echo ""
k8s_log_line "=== Statut monitoring ==="
kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
k8s_log_line "=== Accès Grafana ==="
k8s_log_line "  URL      : http://localhost:${GRAFANA_NODE_PORT}"
k8s_log_line "  Login    : admin"
k8s_log_line "  Password : admin"
k8s_log_line "  Datasource Loki : déjà configuré"
k8s_log_line ""
k8s_log_line "Requête Loki (logs EventApp) : {namespace=\"default\", pod=~\"eventapp.*\"}"
k8s_log_line ""
k8s_log_line "Si le port ${GRAFANA_NODE_PORT} ne répond pas (cluster kind existant), utilisez :"
k8s_log_line "  kubectl port-forward -n ${NAMESPACE} svc/kube-prometheus-grafana 30300:80"
