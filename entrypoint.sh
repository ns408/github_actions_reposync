#!/usr/bin/env sh
set -e

[[ -z "$GITHUB_TOKEN" ]] && (echo "Set the GITHUB_TOKEN environment variable."; exit 1)

sh -c "/github-sync.sh $*"