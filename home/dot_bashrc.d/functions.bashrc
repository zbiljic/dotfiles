#!/usr/bin/env bash

# Create directory and cd into it.
mkd() {
    mkdir -p "$1"
    cd "$1" || exit
}

# Generate password.
genpwd() {
    head /dev/urandom | sha256sum | base64 | head -c "$1" ; echo
}

# Repeat n times command.
repeat() {
    local i max
    max=$1; shift;
    for ((i=1; i <= max ; i++)); do  # --> C-like syntax
        "$@" || exit
    done
}
