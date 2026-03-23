#!/usr/bin/env bash

set -eufo pipefail

NSMB_CONF="/private/etc/nsmb.conf"
NSMB_BACKUP="${NSMB_CONF}.pre-dotfiles.bak"
NSMB_CHANGED=false

sudo -v

# keep the sudo ticket alive while the script runs.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

cat > "${tmp_file}" <<'EOF'
[default]
signing_required=no
streams=yes
notify_off=yes
port445=no_netbios
unix extensions = no
veto files=/._*/.DS_Store/
protocol_vers_map=6
EOF

if sudo test -f "${NSMB_CONF}" && sudo cmp -s "${tmp_file}" "${NSMB_CONF}"; then
    echo "SMB client config already up to date"
else
    if sudo test -f "${NSMB_CONF}" && ! sudo test -f "${NSMB_BACKUP}"; then
        sudo cp "${NSMB_CONF}" "${NSMB_BACKUP}"
    fi

    sudo install -m 0644 "${tmp_file}" "${NSMB_CONF}"
    NSMB_CHANGED=true
    echo "Installed SMB client config at ${NSMB_CONF}"
fi

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

if [[ "${NSMB_CHANGED}" == "true" ]]; then
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
fi
