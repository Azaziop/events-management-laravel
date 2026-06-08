#!/usr/bin/env bash
# Déploie la stack monitoring K8s : Prometheus + Grafana (+ Loki/Promtail si ressources suffisantes).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="$(cd "${SCRIPT_DIR}/../helm/monitoring" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path
NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
GRAFANA_NODE_PORT="${GRAFANA_NODE_PORT:-30300}"
LOKI_ENABLED="${LOKI_ENABLED:-auto}"

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

should_deploy_loki() {
    case "${LOKI_ENABLED}" in
        true | 1 | yes) return 0 ;;
        false | 0 | no) return 1 ;;
        auto)
            # kind/Jenkins : ressources limitées — Loki optionnel
            if k8s_using_kind || k8s_is_ci; then
                return 0
            fi
            return 0
            ;;
        *) return 0 ;;
    esac
}

k8s_log_line "=== Ajout des dépôts Helm (prometheus-community, grafana) ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

declare -a prom_extra_sets=()
if k8s_using_kind || k8s_is_ci; then
    k8s_log_line "Mode kind/CI : stack allégée (Alertmanager/node-exporter désactivés)"
    prom_extra_sets+=(
        --set alertmanager.enabled=false
        --set nodeExporter.enabled=false
        --set prometheus.prometheusSpec.retention=2h
    )
fi

k8s_log_line "=== Déploiement kube-prometheus-stack (Prometheus + Grafana) ==="
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f "${MONITORING_DIR}/kube-prometheus-stack-values.yaml" \
    "${prom_extra_sets[@]}" \
    --wait --timeout 15m

loki_ok=false
if should_deploy_loki; then
    k8s_log_line "=== Déploiement Loki (logs) — timeout 8 min ==="
    if helm upgrade --install loki grafana/loki \
        --namespace "${NAMESPACE}" \
        -f "${MONITORING_DIR}/loki-values.yaml" \
        --wait --timeout 8m 2>&1; then
        loki_ok=true
        k8s_log_line "=== Déploiement Promtail (collecte logs) ==="
        helm upgrade --install promtail grafana/promtail \
            --namespace "${NAMESPACE}" \
            -f "${MONITORING_DIR}/promtail-values.yaml" \
            --timeout 3m || k8s_log_line "Promtail en échec (non bloquant)"
    else
        k8s_log_line "Loki non prêt à temps — Grafana/Prometheus restent disponibles sans logs centralisés"
        helm uninstall loki -n "${NAMESPACE}" 2>/dev/null || true
    fi
else
    k8s_log_line "Loki désactivé (LOKI_ENABLED=false)"
fi

echo ""
k8s_log_line "=== Statut monitoring ==="
kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
k8s_log_line "=== Accès Grafana ==="
if k8s_using_kind && ! docker port eventapp-control-plane 2>/dev/null | grep -q ":${GRAFANA_NODE_PORT}->"; then
    k8s_log_line "  kind sans port ${GRAFANA_NODE_PORT} mappé — utilisez port-forward depuis votre Mac :"
    k8s_log_line "  ./scripts/k8s-monitoring-access.sh grafana"
    k8s_log_line "  → http://localhost:${GRAFANA_NODE_PORT}  (admin / admin)"
else
    k8s_log_line "  URL      : http://localhost:${GRAFANA_NODE_PORT}"
    k8s_log_line "  Login    : admin"
    k8s_log_line "  Password : admin"
fi
if $loki_ok; then
    k8s_log_line "  Loki     : actif — requête {namespace=\"default\", pod=~\"eventapp.*\"}"
else
    k8s_log_line "  Loki     : non déployé — utilisez kubectl logs pour les logs"
fi
k8s_log_line ""
k8s_log_line "Prometheus UI :"
k8s_log_line "  ./scripts/k8s-monitoring-access.sh prometheus"
k8s_log_line "  ou : kubectl port-forward -n ${NAMESPACE} svc/kube-prometheus-kube-prome-prometheus 9090:9090"
