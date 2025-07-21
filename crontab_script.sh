#!/bin/bash

# Author: Urpagin
# Date: 2025-07-21

set -euo pipefail


post_webhook() {
  local err_msg="${DISCORD_WH_ERR_MSG:-error }$1"
  local BODY
  BODY=$(cat <<EOF
  {"username": "GitHub User Mirroring Messenger", "content": "$err_msg"}
EOF
)

  curl -s \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "$DISCORD_WH_URL"
}


atexit() {
  local rc=$?
  (( rc == 0)) && return

  [[ -n "$DISCORD_WH_URL" ]] && post_webhook "$rc"
}

trap 'atexit' EXIT


ENV_VARS=(
  GH_USERNAME
  GH_TOKEN_
  FORGEJO_USERNAME
  FORGEJO_TOKEN
)

for name in "${ENV_VARS[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: environment variable '${name}' isn't initialized"
    exit 1
  fi
done


mirror_to_forgejo() {
  local gh_repo_name="$1"
  local gh_repo_url="$2"
  local gh_repo_is_private="$3"

  # Ignore ignored repos.
  while IFS=, read -r to_ignore_repo; do
    [[ "$gh_repo_name" = "$to_ignore_repo" ]] && echo "INFO: IGNORING $gh_repo_name" && return;
  done <<< "$IGNORED_REPOS"

  json=$(cat <<EOF
  {
      "clone_addr": "$gh_repo_url",
      "repo_name": "$gh_repo_name",
      "repo_owner": "$FORGEJO_USERNAME",
      "mirror": true,
      "auth_token": "$GH_TOKEN_",
      "auth_username": "$GH_USERNAME",
      "private": ${gh_repo_is_private},
      "service": "github",
      "issues": true,
      "pull_requests": true,
      "milestones": true,
      "labels": true,
      "wiki": true,
      "releases": true
  }
EOF
)

  echo "DEBUG: Forgejo JSON request JSON: $json"
  curl -s \
   -X POST "http://forgejo:3000/api/v1/repos/migrate" \
   -H "Authorization: token $FORGEJO_TOKEN" \
   -H "Content-Type: application/json" \
   -d "$json"

}

# Auth to GitHub CLI
gh auth login --hostname github.com --with-token<<<"${GH_TOKEN_}"

# Manual for the 'gh repo list ...' command
# https://cli.github.com/manual/gh_repo_list

#     n PUBLIC
#     n PRIVATE
# and n INTERNAL
# because we're calling gh repo list for reach visibility type.
REPO_LIMIT=3

##### --- PUBLIC MIRRORING ---

# default limit is 30
json_public=$(gh repo list "$GH_USERNAME" -L $REPO_LIMIT --visibility 'public' --json 'name,url')
echo "DEBUG - json_public content: $json_public"

# Mirror PUBLIC repos
jq -r '.[] | [.name, .url] | @tsv' <<< "$json_public" |
while IFS=$'\t' read -r name url; do
  mirror_to_forgejo "$name" "$url" 'false'
done


##### --- PRIVATE MIRRORING ---

# default limit is 30
json_private=$(gh repo list "$GH_USERNAME" -L $REPO_LIMIT --visibility 'private' --json 'name,url')
echo "DEBUG - json_private content: $json_private"

# Mirror PRIVATE repos
jq -r '.[] | [.name, .url] | @tsv' <<< "$json_private" |
while IFS=$'\t' read -r name url; do
  mirror_to_forgejo "$name" "$url" 'true'
done


##### --- INTERNAL MIRRORING ---
# I don't know what internal means, but it's an option.

# default limit is 30
json_internal=$(gh repo list "$GH_USERNAME" -L $REPO_LIMIT --visibility 'internal' --json 'name,url')
echo "DEBUG - json_internal content: $json_internal"


# Mirror INTERNAL repos
jq -r '.[] | [.name, .url] | @tsv' <<< "$json_internal" |
while IFS=$'\t' read -r name url; do
  mirror_to_forgejo "$name" "$url" 'true'
done
