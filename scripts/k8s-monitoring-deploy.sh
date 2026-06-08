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
PROMETHEUS_NODE_PORT="${PROMETHEUS_NODE_PORT:-30909}"
LOKI_ENABLED="${LOKI_ENABLED:-auto}"

if ! command -v helm >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    k8s_log_line "=== Outils K8s absents — installation automatique ==="
    install_k8s_tools_if_missing
fi

if k8s_using_kind; then
    k8s_fix_kind_kubeconfig "$(kind_cluster_name)" || true
fi

if ! k8s_ensure_cluster_access; then
    echo "Cluster Kubernetes inaccessible."
    echo ""
    echo "  Cluster kind (Jenkins) : export KUBECONFIG=~/.kube/kind-eventapp.yaml"
    echo "  Ou démarrer un cluster   : ./scripts/minikube-setup.sh"
    echo "  Forcer kind sur Mac      : K8S_CLUSTER=kind ./scripts/minikube-setup.sh"
    exit 1
fi

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
    k8s_log_line "Mode kind/CI : stack allégée (Alertmanager désactivé)"
    prom_extra_sets+=(
        --set alertmanager.enabled=false
        --set prometheus.prometheusSpec.retention=2h
    )
fi
if [[ "${NODE_EXPORTER_ENABLED:-true}" =~ ^(false|0|no)$ ]]; then
    k8s_log_line "node-exporter désactivé (NODE_EXPORTER_ENABLED=false) — panneau CPU par Node vide"
    prom_extra_sets+=(--set nodeExporter.enabled=false)
fi

k8s_log_line "=== Déploiement kube-prometheus-stack (Prometheus + Grafana) ==="
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f "${MONITORING_DIR}/kube-prometheus-stack-values.yaml" \
    "${prom_extra_sets[@]}" \
    --wait --timeout 15m

k8s_log_line "=== Dashboard Grafana « namespace » (exercice monitoring) ==="
kubectl create configmap grafana-dashboard-eventapp-namespace \
    --from-file=namespace.json="${MONITORING_DIR}/grafana-dashboard-namespace.json" \
    --namespace "${NAMESPACE}" \
    --dry-run=client -o yaml | \
    kubectl label --local -f - grafana_dashboard=1 -o yaml | \
    kubectl apply -f -

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
    helm uninstall loki -n "${NAMESPACE}" 2>/dev/null || true
fi

echo ""
k8s_log_line "=== Statut monitoring ==="
kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
k8s_log_line "=== Accès monitoring ==="
k8s_log_line "  Kubeconfig : eval \"\$(./scripts/k8s-env.sh)\""
k8s_log_line "  Démarrer   : ./scripts/k8s-monitoring-start.sh"
k8s_log_line ""
k8s_log_line "  Grafana    : http://localhost:${GRAFANA_NODE_PORT}  (admin / admin)"
k8s_log_line "  Prometheus : http://localhost:9090  (via port-forward)"
k8s_log_line "  Dashboard  : Dashboards → namespace"
if k8s_using_kind && docker port eventapp-control-plane 2>/dev/null | grep -q ":${GRAFANA_NODE_PORT}->"; then
    k8s_log_line "  (Grafana NodePort ${GRAFANA_NODE_PORT} mappé sur kind)"
fi
if k8s_using_kind && docker port eventapp-control-plane 2>/dev/null | grep -q ":${PROMETHEUS_NODE_PORT}->"; then
    k8s_log_line "  (Prometheus NodePort ${PROMETHEUS_NODE_PORT} → http://localhost:${PROMETHEUS_NODE_PORT})"
else
    k8s_log_line "  Prometheus nécessite : ./scripts/k8s-monitoring-start.sh"
fi
if $loki_ok; then
    k8s_log_line "  Loki       : actif — {namespace=\"default\", pod=~\"eventapp.*\"}"
else
    k8s_log_line "  Loki       : non déployé"
fi
