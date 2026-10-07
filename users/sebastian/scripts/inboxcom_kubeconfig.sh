#!/usr/bin/env bash
# Kubeconfigs of DigitalOcean Kubernetes clusters, in KUBECONFIG_DIR:
# - config.<name>.yaml: one per cluster, its context named <name>
# - config.yaml: all of them merged
#
# Set by users/sebastian/work.nix:
# - CLUSTERS_FILE: one "<name> <cluster>" per line (a secret)
# - DEFAULT_CONTEXT_FILE: the <name> to use as the merged file's current context (a secret)
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

# Merged, with the default context as current one (none if it isn't one of the clusters)
merged="${KUBECONFIG_DIR}/config.yaml"
default="$(tr -d '[:space:]' < "${DEFAULT_CONTEXT_FILE}")"
KUBECONFIG="$(IFS=:; echo "${files[*]}")" kubectl config view --flatten > "${tmp}/config.yaml"
KUBECONFIG="${tmp}/config.yaml" kubectl config unset current-context > /dev/null
if KUBECONFIG="${tmp}/config.yaml" kubectl config get-contexts "${default}" > /dev/null 2>&1; then
    KUBECONFIG="${tmp}/config.yaml" kubectl config use-context "${default}" > /dev/null
else
    echo "Default context \"${default}\" is not one of the clusters: no current context" >&2
fi
install -m 600 "${tmp}/config.yaml" "${merged}"
echo "Merged: ${merged} ($(KUBECONFIG="${merged}" kubectl config get-contexts -o name | paste -sd ' '), current: $(KUBECONFIG="${merged}" kubectl config current-context 2> /dev/null || echo none))" >&2
