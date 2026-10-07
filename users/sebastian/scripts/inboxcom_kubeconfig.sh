# Kubeconfigs of DigitalOcean Kubernetes clusters, in KUBECONFIG_DIR:
# - config.<name>.yaml: one per cluster, its context named <name>
# - config.yaml: all of them merged
#
# Set by users/sebastian/work.nix:
# - CLUSTERS_FILE: one "<name> <cluster>" per line (a secret)
# - DOCTL_CONTEXT: the doctl context holding the account's token (doctl auth init --context <context>)
# - KUBECONFIG_DIR
# Re-run when a cluster changes.
#
# Usage: inboxcom_kubeconfig

install -d -m 700 "${KUBECONFIG_DIR}"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

files=()
while read -r name cluster; do
    [ -n "${name}" ] || continue
    # Saved into an empty file, then its context (doctl names it do-<region>-<cluster>) renamed to <name>. The doctl
    # context is also written into the credential command: tokens always come from that account.
    KUBECONFIG="${tmp}/${name}.yaml" doctl --context "${DOCTL_CONTEXT}" kubernetes cluster kubeconfig save "${cluster}" >&2
    KUBECONFIG="${tmp}/${name}.yaml" kubectl config rename-context \
        "$(KUBECONFIG="${tmp}/${name}.yaml" kubectl config current-context)" "${name}" > /dev/null
    install -m 600 "${tmp}/${name}.yaml" "${KUBECONFIG_DIR}/config.${name}.yaml"
    files+=("${KUBECONFIG_DIR}/config.${name}.yaml")
    echo "${name}: ${KUBECONFIG_DIR}/config.${name}.yaml" >&2
done < "${CLUSTERS_FILE}"

if [ "${#files[@]}" -eq 0 ]; then
    echo "No cluster in ${CLUSTERS_FILE}" >&2
    exit 1
fi

# Merged: keep the current context if it still exists, otherwise none (pick one with kubectl config use-context)
merged="${KUBECONFIG_DIR}/config.yaml"
previous="$(KUBECONFIG="${merged}" kubectl config current-context 2> /dev/null || true)"
KUBECONFIG="$(IFS=:; echo "${files[*]}")" kubectl config view --flatten > "${tmp}/config.yaml"
KUBECONFIG="${tmp}/config.yaml" kubectl config unset current-context > /dev/null
if [ -n "${previous}" ] && KUBECONFIG="${tmp}/config.yaml" kubectl config get-contexts "${previous}" > /dev/null 2>&1; then
    KUBECONFIG="${tmp}/config.yaml" kubectl config use-context "${previous}" > /dev/null
fi
install -m 600 "${tmp}/config.yaml" "${merged}"
echo "Merged: ${merged} ($(KUBECONFIG="${merged}" kubectl config get-contexts -o name | tr '\n' ' '))" >&2
