#!/usr/bin/env bash

set -eufo pipefail

MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-$HOME/.config/mise}"
MISE_BIN_DIR="${HOME}/.local/cli/mise/bin"

if ! command -v mise >/dev/null 2>&1; then
  if [[ -x "${MISE_BIN_DIR}/mise" ]]; then
    export PATH="${MISE_BIN_DIR}:${PATH}"
  else
    echo "mise not found, skipping..."
    exit 0
  fi
fi

if [[ ! -d "${MISE_CONFIG_DIR}" ]]; then
  echo "mise config not found at ${MISE_CONFIG_DIR}, skipping..."
  exit 0
fi

# "installing configured mise tools..."
mise install

# "pruning unused mise tool versions..."
mise prune --yes
