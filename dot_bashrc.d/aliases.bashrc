#!/usr/bin/env bash

##
## Terminal
##

# easier navigation with dots
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# some ls aliases
alias ll='ls -alF'
alias lh='ls -alFh'
alias la='ls -A'
alias l='ls -CF'

# some exa aliases
alias e='exa -lag'
alias ee='exa -abghHliS'
alias et='exa -bghHliS -T -L 2'
alias etr='exa -T'
alias etra='exa -a -T'

# some du aliases
alias d='du -hc -d 1'

# date aliases
alias epoch='date +%s'
