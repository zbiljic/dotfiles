#!/usr/bin/env sh
# shellcheck shell=dash

set -e # -e: exit on error

if [ ! "$(command -v chezmoi)" ]; then
    bin_dir="$HOME/.local/bin"
    chezmoi="$bin_dir/chezmoi"
    _dld=""
    if [ "$(command -v curl)" ]; then
        _dld=curl
    elif [ "$(command -v wget)" ]; then
        _dld=wget
    else
        if [ -f /etc/os-release ]; then
            # shellcheck source=/dev/null
            . /etc/os-release
        fi
        case $ID in
        "ubuntu")
            echo "=> Installing busybox..." >&2
            apt -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -qy busybox ca-certificates < /dev/null > /dev/null && ln -sv /usr/bin/busybox /usr/bin/wget
            _dld=wget
            ;;
        *)
            echo "unsupported operating system"
            exit 1
            ;;
        esac
    fi
    if [ "$_dld" = curl ]; then
        sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
    elif [ "$_dld" = wget ]; then
        sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
    else
        echo "To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi
else
    chezmoi=chezmoi
fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
# exec: replace current process with chezmoi init
exec "$chezmoi" init --apply "--source=$script_dir"
