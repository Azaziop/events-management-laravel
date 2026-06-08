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

install_k8s_tools_if_missing() {
    k8s_setup_path

    local os arch bin_dir
    os="$(k8s_detect_os)"
    arch="$(k8s_detect_arch)"
    bin_dir="$(k8s_bin_dir)"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl est requis pour installer kubectl / helm / minikube." >&2
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

    if ! command -v minikube >/dev/null 2>&1; then
        k8s_install_tool minikube \
            "https://storage.googleapis.com/minikube/releases/latest/minikube-${os}-${arch}" \
            "${bin_dir}/minikube"
    fi

    echo "=== Versions des outils K8s ==="
    kubectl version --client --short 2>/dev/null || kubectl version --client
    helm version --short 2>/dev/null || helm version
    minikube version --short 2>/dev/null || minikube version
}

k8s_is_ci() {
    [ -n "${JENKINS_URL:-}" ] || [ "${CI:-}" = "true" ]
}

k8s_log_line() {
    printf '%s %s\n' "$(date '+%H:%M:%S')" "$*"
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
            | head -1 \
            | sed 's/.*"\(v[^"]*\)".*/\1/'
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
