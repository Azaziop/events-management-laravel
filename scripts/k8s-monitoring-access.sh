#!/usr/bin/env bash
# Accès Grafana / Prometheus depuis le Mac (kind sans port 30300 mappé).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path
NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
GRAFANA_LOCAL_PORT="${GRAFANA_LOCAL_PORT:-30300}"
PROMETHEUS_LOCAL_PORT="${PROMETHEUS_LOCAL_PORT:-9090}"

fix_kubeconfig_for_mac() {
    local cluster container api_port kubeconfig
    cluster="$(kind_cluster_name)"
    container="${cluster}-control-plane"

    if ! docker ps --format '{{.Names}}' | grep -qx "${container}"; then
        echo "Cluster kind/${cluster} introuvable. Lancez d'abord le pipeline Jenkins ou ./scripts/minikube-setup.sh"
        exit 1
    fi

    api_port="$(docker port "${container}" 6443/tcp 2>/dev/null | head -1 | cut -d: -f2 || true)"
    if [ -z "$api_port" ]; then
        echo "Port API kind introuvable."
        exit 1
    fi

    mkdir -p "${HOME}/.kube"
    kubeconfig="${HOME}/.kube/kind-${cluster}.yaml"

    docker cp "${container}:/etc/kubernetes/admin.conf" /tmp/kind-admin.conf
    sed "s|server: https://[^:]*:6443|server: https://127.0.0.1:${api_port}|" \
        /tmp/kind-admin.conf > "${kubeconfig}"

    export KUBECONFIG="${kubeconfig}"
    kubectl config use-context "kind-${cluster}" >/dev/null
    echo "KUBECONFIG=${kubeconfig}"
}

wait_for_svc() {
    local ns="$1" name="$2" i
    for i in $(seq 1 30); do
        if kubectl get svc -n "$ns" "$name" >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
    done
    echo "Service ${name} introuvable dans ${ns}."
    kubectl get svc -n "$ns" || true
    exit 1
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [grafana|prometheus|both]

Expose Grafana et/ou Prometheus sur localhost via kubectl port-forward.

  grafana     http://localhost:${GRAFANA_LOCAL_PORT}  (admin / admin)
  prometheus  http://localhost:${PROMETHEUS_LOCAL_PORT}
  both        les deux (défaut)

Exemple :
  $(basename "$0") grafana

Dans un autre terminal, exportez KUBECONFIG si besoin :
  export KUBECONFIG=~/.kube/kind-eventapp.yaml
EOF
}

main() {
    local mode="${1:-both}"
    fix_kubeconfig_for_mac >/dev/null

    case "$mode" in
        grafana)
            wait_for_svc "$NAMESPACE" kube-prometheus-grafana
            echo ""
            echo "Grafana → http://localhost:${GRAFANA_LOCAL_PORT}  (admin / admin)"
            echo "Ctrl+C pour arrêter."
            echo ""
            kubectl port-forward -n "$NAMESPACE" svc/kube-prometheus-grafana "${GRAFANA_LOCAL_PORT}:80"
            ;;
        prometheus)
            wait_for_svc "$NAMESPACE" kube-prometheus-kube-prome-prometheus
            echo ""
            echo "Prometheus → http://localhost:${PROMETHEUS_LOCAL_PORT}"
            echo "Ctrl+C pour arrêter."
            echo ""
            kubectl port-forward -n "$NAMESPACE" svc/kube-prometheus-kube-prome-prometheus "${PROMETHEUS_LOCAL_PORT}:9090"
            ;;
        both)
            wait_for_svc "$NAMESPACE" kube-prometheus-grafana
            wait_for_svc "$NAMESPACE" kube-prometheus-kube-prome-prometheus
            echo ""
            echo "Grafana    → http://localhost:${GRAFANA_LOCAL_PORT}  (admin / admin)"
            echo "Prometheus → http://localhost:${PROMETHEUS_LOCAL_PORT}"
            echo "Ctrl+C pour arrêter les deux."
            echo ""
            kubectl port-forward -n "$NAMESPACE" svc/kube-prometheus-grafana "${GRAFANA_LOCAL_PORT}:80" &
            local grafana_pid=$!
            kubectl port-forward -n "$NAMESPACE" svc/kube-prometheus-kube-prome-prometheus "${PROMETHEUS_LOCAL_PORT}:9090" &
            local prom_pid=$!
            trap 'kill $grafana_pid $prom_pid 2>/dev/null || true' INT TERM EXIT
            wait
            ;;
        -h | --help | help)
            usage
            ;;
        *)
            echo "Mode inconnu : $mode"
            usage
            exit 1
            ;;
    esac
}

main "${1:-both}"
