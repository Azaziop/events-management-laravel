#!/usr/bin/env bash
# Outils K8s partagés : PATH + installation auto (Jenkins-in-Docker / CI Linux).

k8s_bin_dir() {
    echo "${K8S_TOOLS_DIR:-${HOME}/.local/bin}"
}

k8s_setup_path() {
    local bin_dir
    bin_dir="$(k8s_bin_dir)"
    mkdir -p "$bin_dir"
    export PATH="$bin_dir:$PATH"
}

k8s_detect_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo amd64 ;;
        aarch64 | arm64) echo arm64 ;;
        *)
            echo "Architecture non supportée : $(uname -m)" >&2
            return 1
            ;;
    esac
}

k8s_detect_os() {
    case "$(uname -s)" in
        Linux) echo linux ;;
        Darwin) echo darwin ;;
        *)
            echo "OS non supporté : $(uname -s)" >&2
            return 1
            ;;
    esac
}

k8s_install_tool() {
    local name="$1" url="$2" dest="$3"
    echo "=== Installation ${name} ==="
    curl -fsSL "$url" -o "$dest"
    chmod +x "$dest"
}

k8s_is_ci() {
    [ -n "${JENKINS_URL:-}" ] || [ "${CI:-}" = "true" ]
}

k8s_is_docker_in_docker() {
    [ -f /.dockerenv ] && [ -S /var/run/docker.sock ]
}

k8s_should_use_kind() {
    if [ "${K8S_CLUSTER:-}" = "kind" ]; then
        return 0
    fi
    if [ "${K8S_CLUSTER:-}" = "minikube" ]; then
        return 1
    fi
    k8s_is_docker_in_docker
}

k8s_log_line() {
    printf '%s %s\n' "$(date '+%H:%M:%S')" "$*"
}

install_kind_if_missing() {
    k8s_setup_path
    if command -v kind >/dev/null 2>&1; then
        return 0
    fi
    local os arch bin_dir kind_ver
    os="$(k8s_detect_os)"
    arch="$(k8s_detect_arch)"
    bin_dir="$(k8s_bin_dir)"
    kind_ver="v0.26.0"
    k8s_install_tool kind \
        "https://kind.sigs.k8s.io/dl/${kind_ver}/kind-${os}-${arch}" \
        "${bin_dir}/kind"
}

install_k8s_tools_if_missing() {
    k8s_setup_path

    local os arch bin_dir
    os="$(k8s_detect_os)"
    arch="$(k8s_detect_arch)"
    bin_dir="$(k8s_bin_dir)"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl est requis pour installer kubectl / helm / kind / minikube." >&2
        return 1
    fi

    if ! command -v kubectl >/dev/null 2>&1; then
        local kver
        kver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
        k8s_install_tool kubectl \
            "https://dl.k8s.io/release/${kver}/bin/${os}/${arch}/kubectl" \
            "${bin_dir}/kubectl"
    fi

    if ! command -v helm >/dev/null 2>&1; then
        local helm_ver helm_tgz tmp_dir
        helm_ver="v3.16.4"
        helm_tgz="helm-${helm_ver}-${os}-${arch}.tar.gz"
        tmp_dir="$(mktemp -d)"
        curl -fsSL "https://get.helm.sh/${helm_tgz}" -o "${tmp_dir}/${helm_tgz}"
        tar -xzf "${tmp_dir}/${helm_tgz}" -C "$tmp_dir"
        mv "${tmp_dir}/${os}-${arch}/helm" "${bin_dir}/helm"
        chmod +x "${bin_dir}/helm"
        rm -rf "$tmp_dir"
    fi

    if k8s_should_use_kind; then
        install_kind_if_missing
    elif ! command -v minikube >/dev/null 2>&1; then
        k8s_install_tool minikube \
            "https://storage.googleapis.com/minikube/releases/latest/minikube-${os}-${arch}" \
            "${bin_dir}/minikube"
    fi

    echo "=== Versions des outils K8s ==="
    kubectl version --client --short 2>/dev/null || kubectl version --client
    helm version --short 2>/dev/null || helm version
    if command -v kind >/dev/null 2>&1; then
        kind version
    fi
    if command -v minikube >/dev/null 2>&1; then
        minikube version --short 2>/dev/null || minikube version
    fi
}

kind_cluster_name() {
    echo "${KIND_CLUSTER_NAME:-eventapp}"
}

k8s_fix_kind_kubeconfig() {
    local cluster="${1:-$(kind_cluster_name)}"
    local container="${cluster}-control-plane"
    local ip

    # Sur Mac (hors Jenkins-in-Docker), kind kubeconfig via 127.0.0.1 fonctionne déjà.
    if [ "$(uname -s)" = "Darwin" ] && ! k8s_is_docker_in_docker; then
        return 0
    fi

    ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container" 2>/dev/null || true)"
    if [ -z "$ip" ]; then
        k8s_log_line "Impossible de résoudre l'IP du nœud kind — kubeconfig inchangé."
        return 1
    fi

    k8s_log_line "kubectl → https://${ip}:6443 (kind/${cluster})"
    kubectl config set-cluster "kind-${cluster}" \
        --server="https://${ip}:6443" \
        --insecure-skip-tls-verify=true
    kubectl config use-context "kind-${cluster}"
}

k8s_cleanup_broken_minikube() {
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx minikube; then
        k8s_log_line "Suppression du conteneur minikube (incompatible Jenkins-in-Docker)..."
        docker rm -f minikube 2>/dev/null || true
    fi
    if command -v minikube >/dev/null 2>&1; then
        minikube delete -p minikube --purge 2>/dev/null || true
    fi
}

kind_setup_cluster() {
    local cluster node_port grafana_port prometheus_port config_file kubeconfig
    cluster="$(kind_cluster_name)"
    node_port="${KIND_NODE_PORT:-30080}"
    grafana_port="${GRAFANA_NODE_PORT:-30300}"
    prometheus_port="${PROMETHEUS_NODE_PORT:-30909}"
    kubeconfig="${HOME}/.kube/kind-${cluster}.yaml"

    install_k8s_tools_if_missing
    command -v kind >/dev/null 2>&1 || { echo "kind introuvable"; return 1; }

    if kubectl cluster-info --context "kind-${cluster}" >/dev/null 2>&1; then
        k8s_log_line "Cluster kind/${cluster} déjà opérationnel."
        k8s_fix_kind_kubeconfig "$cluster" || true
        kind get kubeconfig --name "$cluster" > "${kubeconfig}" 2>/dev/null || true
        export KUBECONFIG="${kubeconfig}"
        kubectl config use-context "kind-${cluster}" 2>/dev/null || true
        kubectl cluster-info --context "kind-${cluster}"
        return 0
    fi

    k8s_cleanup_broken_minikube

    config_file="$(mktemp)"
    cat > "$config_file" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: ${node_port}
        hostPort: ${node_port}
        protocol: TCP
      - containerPort: ${grafana_port}
        hostPort: ${grafana_port}
        protocol: TCP
      - containerPort: ${prometheus_port}
        hostPort: ${prometheus_port}
        protocol: TCP
EOF

    k8s_log_line "=== Création du cluster kind (${cluster}) — 2 à 5 min au premier lancement ==="
    kind create cluster --name "$cluster" --config "$config_file" --wait 5m
    rm -f "$config_file"

    kind get kubeconfig --name "$cluster" > "${kubeconfig}"
    export KUBECONFIG="${kubeconfig}"
    kubectl config use-context "kind-${cluster}" 2>/dev/null || true
    k8s_fix_kind_kubeconfig "$cluster"
    kubectl cluster-info --context "kind-${cluster}"
}

k8s_using_kind() {
    kubectl config current-context 2>/dev/null | grep -qE '^kind-'
}

# Corrige KUBECONFIG si le contexte courant (ex. minikube arrêté) est inaccessible
# mais qu'un cluster kind local tourne encore (cas Mac + Jenkins/kind).
k8s_ensure_cluster_access() {
    if kubectl cluster-info >/dev/null 2>&1; then
        if k8s_using_kind && { k8s_is_docker_in_docker || k8s_is_ci; }; then
            k8s_fix_kind_kubeconfig "$(kind_cluster_name)" 2>/dev/null || true
        fi
        return 0
    fi

    local cluster container kubeconfig ctx api_port

    cluster="$(kind_cluster_name)"
    container="${cluster}-control-plane"
    kubeconfig="${HOME}/.kube/kind-${cluster}.yaml"

    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${container}"; then
        return 1
    fi

    k8s_log_line "Cluster kind/${cluster} détecté — correction du kubeconfig (contexte minikube inaccessible)."
    mkdir -p "${HOME}/.kube"

    if command -v kind >/dev/null 2>&1; then
        kind get kubeconfig --name "${cluster}" > "${kubeconfig}" 2>/dev/null || true
    fi

    if [ ! -s "${kubeconfig}" ]; then
        api_port="$(docker port "${container}" 6443/tcp 2>/dev/null | sed -n '1s/.*://p' || true)"
        if [ -z "$api_port" ]; then
            return 1
        fi
        docker cp "${container}:/etc/kubernetes/admin.conf" /tmp/kind-admin.conf 2>/dev/null || return 1
        sed "s|server: https://[^:]*:6443|server: https://127.0.0.1:${api_port}|" \
            /tmp/kind-admin.conf > "${kubeconfig}"
    fi

    export KUBECONFIG="${kubeconfig}"
    ctx="$(kubectl config get-contexts -o name 2>/dev/null | sed -n '1p')"
    if [ -n "$ctx" ]; then
        kubectl config use-context "$ctx" >/dev/null 2>&1 || true
    fi

    kubectl cluster-info >/dev/null 2>&1
}

k8s_load_image_to_cluster() {
    local image_ref="$1"
    local cluster

    if k8s_using_kind; then
        cluster="$(kind_cluster_name)"
        k8s_log_line "=== Chargement de l'image dans kind : ${image_ref} ==="
        if docker image inspect "${image_ref}" >/dev/null 2>&1; then
            kind load docker-image "${image_ref}" --name "$cluster"
            return 0
        fi
        return 1
    fi

    if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
        k8s_log_line "=== Chargement de l'image dans Minikube : ${image_ref} ==="
        if docker image inspect "${image_ref}" >/dev/null 2>&1; then
            minikube image load "${image_ref}"
            return 0
        fi
        return 1
    fi

    return 1
}

k8s_print_app_url() {
    local release="${1:-eventapp}"
    local namespace="${2:-default}"
    local node_port="${KIND_NODE_PORT:-30080}"

    if k8s_using_kind; then
        echo "http://localhost:${node_port}"
        return 0
    fi

    if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
        minikube service "${release}-events-management" -n "${namespace}" --url 2>/dev/null \
            || minikube service "${release}" -n "${namespace}" --url 2>/dev/null \
            || echo "http://$(minikube ip):${node_port}"
    fi
}

minikube_profile_exists() {
    local profile="${1:-minikube}"
    [ -d "${HOME}/.minikube/profiles/${profile}" ] \
        || minikube profile list 2>/dev/null | awk '{print $1}' | grep -qx "${profile}"
}

minikube_profile_k8s_version() {
    local profile="${1:-minikube}"
    local config="${HOME}/.minikube/profiles/${profile}/config.json"

    if [ -f "$config" ]; then
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
print(data.get('KubernetesConfig', {}).get('KubernetesVersion', ''))
" "$config" 2>/dev/null && return 0
        fi
        grep -o '"KubernetesVersion"[[:space:]]*:[[:space:]]*"v[^"]*"' "$config" \
            | sed -n '1s/.*"\(v[^"]*\)".*/\1/p'
    fi
}

_minikube_run_start() {
    local -a args=("$@")
    local exit_code=0

    export MINIKUBE_IN_STYLE=false

    if command -v stdbuf >/dev/null 2>&1; then
        set +o pipefail
        stdbuf -oL -eL minikube start "${args[@]}" --alsologtostderr -v=1 2>&1 | while IFS= read -r line; do
            k8s_log_line "$line"
        done
        exit_code="${PIPESTATUS[0]}"
        set -o pipefail
    else
        minikube start "${args[@]}" --alsologtostderr -v=1 || exit_code=$?
    fi

    return "$exit_code"
}

minikube_start_with_progress() {
    local -a args=("$@")

    if minikube status -p minikube >/dev/null 2>&1; then
        k8s_log_line "Minikube déjà démarré — réutilisation du cluster existant."
        return 0
    fi

    if minikube_profile_exists minikube; then
        k8s_log_line "Profil Minikube existant — redémarrage sans re-téléchargement complet."
    else
        k8s_log_line "Premier démarrage : téléchargement Kubernetes (~300 Mo)."
        k8s_log_line "Comptez 10 à 15 min. Les builds suivants seront bien plus rapides."
    fi

    if _minikube_run_start "${args[@]}"; then
        return 0
    fi

    k8s_log_line "Échec au démarrage — suppression du profil minikube et nouvelle tentative..."
    minikube delete -p minikube --purge 2>/dev/null || true
    docker rm -f minikube 2>/dev/null || true

    local -a fresh_args=()
    local arg skip_version=false
    for arg in "${args[@]}"; do
        if $skip_version; then
            skip_version=false
            continue
        fi
        if [ "$arg" = "--kubernetes-version" ]; then
            skip_version=true
            continue
        fi
        fresh_args+=("$arg")
    done

    if [ -n "${MINIKUBE_K8S_VERSION:-}" ]; then
        fresh_args+=(--kubernetes-version="${MINIKUBE_K8S_VERSION}")
    fi

    _minikube_run_start "${fresh_args[@]}"
}

minikube_setup_cluster() {
    local minikube_cpus minikube_memory minikube_wait_timeout
    minikube_cpus="${MINIKUBE_CPUS:-2}"
    minikube_memory="${MINIKUBE_MEMORY:-2048}"
    minikube_wait_timeout="${MINIKUBE_WAIT_TIMEOUT:-15m}"

    declare -a start_args=(
        --driver=docker
        --cpus="${minikube_cpus}"
        --memory="${minikube_memory}"
        --wait=all
        --wait-timeout="${minikube_wait_timeout}"
        --force
    )

    local k8s_version=""
    if minikube_profile_exists minikube; then
        k8s_version="$(minikube_profile_k8s_version minikube || true)"
        if [ -n "$k8s_version" ]; then
            k8s_log_line "=== Démarrage Minikube (driver=docker, k8s=${k8s_version}, cpus=${minikube_cpus}, memory=${minikube_memory}Mi) ==="
            start_args+=(--kubernetes-version="${k8s_version}")
        else
            k8s_log_line "=== Démarrage Minikube (driver=docker, profil existant, cpus=${minikube_cpus}, memory=${minikube_memory}Mi) ==="
        fi
    elif [ -n "${MINIKUBE_K8S_VERSION:-}" ]; then
        k8s_log_line "=== Démarrage Minikube (driver=docker, k8s=${MINIKUBE_K8S_VERSION}, cpus=${minikube_cpus}, memory=${minikube_memory}Mi) ==="
        start_args+=(--kubernetes-version="${MINIKUBE_K8S_VERSION}")
    else
        k8s_log_line "=== Démarrage Minikube (driver=docker, cpus=${minikube_cpus}, memory=${minikube_memory}Mi) ==="
    fi

    minikube_start_with_progress "${start_args[@]}"

    k8s_log_line "=== Activation des addons ==="
    minikube addons enable storage-provisioner
    minikube addons enable default-storageclass

    k8s_log_line "=== Contexte kubectl ==="
    kubectl config use-context minikube
    kubectl cluster-info
}
