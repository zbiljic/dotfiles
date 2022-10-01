#!/usr/bin/env bash

##
## Docker
##

# List all Docker images
alias dimg='docker images -a'
# List all Docker containers (running and exited)
alias dps='docker ps -a'
# Stop all Docker containers
alias dsall='docker stop $(docker ps -a -q)'
# Stop restarting containers
alias dsu='docker update --restart=no $(docker ps -a -q)'
# Remove all exited docker containers
alias drm='docker rm $(docker ps -q -f status=exited)'
# Remove docker image
alias drmi='docker rmi'
# Remove dangling docker images
alias drmid='docker rmi $(docker images -f dangling=true -q)'
# Show command used for starting container
alias di='docker inspect -f "{{.Name}} {{.Config.Cmd}}" $(docker ps -a -q)'
# List all dangling volumes
alias dvls='docker volume ls -qf dangling=true'
# Clear all orphaned volumes
alias dvrm='docker volume rm $(docker volume ls -qf dangling=true)'
