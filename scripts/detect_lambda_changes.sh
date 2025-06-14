#!/bin/bash

set -e

LAYER_PATH=$1
EVENT_NAME=$2
BASE_REF=$3

if [[ "$EVENT_NAME" == "pull_request" ]]; then
  git fetch origin "$BASE_REF" --depth=1
  git diff --quiet origin/"$BASE_REF" -- "$LAYER_PATH"
else
  git fetch origin/main
  git diff --quiet $(git merge-base HEAD origin/main) HEAD -- $LAYER_PATH
fi
