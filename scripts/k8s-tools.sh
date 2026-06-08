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
