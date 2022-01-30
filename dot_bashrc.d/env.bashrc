#!/usr/bin/env bash

export TZ=""

# Increase Bash history size. Allow more entries; the default is 500.
HISTSIZE='262144';
HISTFILESIZE="${HISTSIZE}";
# Omit duplicates and commands that begin with a space from history.
HISTCONTROL='ignoreboth';

if [ -d "$HOME/.local/bin" ]; then
    if [[ $PATH != *"$HOME/.local/bin"* ]]; then
        PATH="$HOME/.local/bin:$PATH"
    fi
fi
