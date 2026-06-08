#!/usr/bin/env bash
# Démarre Grafana + Prometheus en arrière-plan (port-forward) sur le Mac.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/k8s-tools.sh
source "${SCRIPT_DIR}/k8s-tools.sh"

k8s_setup_path
NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
GRAFANA_LOCAL_PORT="${GRAFANA_LOCAL_PORT:-30300}"
PROMETHEUS_LOCAL_PORT="${PROMETHEUS_LOCAL_PORT:-9090}"
PID_DIR="${TMPDIR:-/tmp}/eventapp-monitoring"
GRAFANA_PID="${PID_DIR}/grafana.pid"
PROM_PID="${PID_DIR}/prometheus.pid"

stop_one() {
    local pid_file="$1" name="$2"
    if [ -f "$pid_file" ]; then
        local pid
        pid="$(cat "$pid_file")"
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            echo "Arrêt ${name} (pid ${pid})"
        fi
        rm -f "$pid_file"
    fi
}

stop_all() {
    stop_one "$GRAFANA_PID" "Grafana"
    stop_one "$PROM_PID" "Prometheus"
}

port_in_use() {
    local port="$1"
    lsof -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
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

start_port_forward() {
    local svc="$1" local_port="$2" remote_port="$3" pid_file="$4" label="$5" i

    if port_in_use "$local_port"; then
        if curl -sf "http://127.0.0.1:${local_port}/" >/dev/null 2>&1 \
            || curl -sf "http://127.0.0.1:${local_port}/-/ready" >/dev/null 2>&1; then
            echo "${label} déjà accessible sur http://localhost:${local_port}"
            return 0
        fi
        echo "Port ${local_port} occupé mais ${label} ne répond pas — arrêtez l'autre processus."
        return 1
    fi

    kubectl port-forward -n "$NAMESPACE" "svc/${svc}" "${local_port}:${remote_port}" \
        >/dev/null 2>&1 &
    echo $! > "$pid_file"

    for i in $(seq 1 10); do
        sleep 1
        if ! kill -0 "$(cat "$pid_file")" 2>/dev/null; then
            echo "Échec port-forward ${label}. Lancez : ./scripts/k8s-monitoring-access.sh"
            rm -f "$pid_file"
            return 1
        fi
        if curl -sf "http://127.0.0.1:${local_port}/" >/dev/null 2>&1 \
            || curl -sf "http://127.0.0.1:${local_port}/-/ready" >/dev/null 2>&1; then
            echo "${label} → http://localhost:${local_port}  (port-forward pid $(cat "$pid_file"))"
            return 0
        fi
    done

    echo "${label} démarré (pid $(cat "$pid_file")) — vérifiez http://localhost:${local_port}"
}

case "${1:-start}" in
    stop)
        stop_all
        exit 0
        ;;
    restart)
        stop_all
        ;;
    start)
        ;;
    *)
        echo "Usage: $(basename "$0") [start|stop|restart]"
        exit 1
        ;;
esac

if ! k8s_ensure_cluster_access; then
    echo "Cluster inaccessible. Lancez ./scripts/minikube-setup.sh"
    exit 1
fi

mkdir -p "$PID_DIR"
stop_all

wait_for_svc "$NAMESPACE" kube-prometheus-grafana
wait_for_svc "$NAMESPACE" kube-prometheus-kube-prome-prometheus

echo ""
echo "KUBECONFIG=${KUBECONFIG}  context=$(kubectl config current-context)"
echo ""

start_port_forward kube-prometheus-grafana "$GRAFANA_LOCAL_PORT" 80 "$GRAFANA_PID" "Grafana"
start_port_forward kube-prometheus-kube-prome-prometheus "$PROMETHEUS_LOCAL_PORT" 9090 "$PROM_PID" "Prometheus"

echo ""
echo "Grafana    : http://localhost:${GRAFANA_LOCAL_PORT}  (admin / admin)"
echo "Prometheus : http://localhost:${PROMETHEUS_LOCAL_PORT}"
echo ""
echo "Arrêter : ./scripts/k8s-monitoring-start.sh stop"
