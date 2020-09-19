#!/bin/bash

# Place this script in the parent directory of /homebrew-core git project
set -e # stop the script on first error
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOMEBREW_DIR="$SCRIPT_DIR/homebrew-core"
(cd $HOMEBREW_DIR; git pull upstream master)

CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check/terraform"
CHECKPOINT_RESULTS="$(curl "$CHECKPOINT_URL")"
echo "CHECKPOINT_RESULTS=$(echo $CHECKPOINT_RESULTS | jq)"

CURRENT_VERSION="$(echo $CHECKPOINT_RESULTS | jq -r '.current_version')"
echo "CURRENT_VERSION=$CURRENT_VERSION"

URL="https://github.com/hashicorp/terraform/archive/v$CURRENT_VERSION.tar.gz"
echo "URL=$URL"

SHA256="$(curl -L $URL | sha256sum | awk '{print $1}')"
echo "SHA256=$SHA256"

echo "Replacing from 'sha256' on first instance of that string in file (the hash of the desired file)..."
NEW_SHA256_LINE="sha256 \"$SHA256\""
sed -i "0,/sha256.*/s//$NEW_SHA256_LINE/" "$HOMEBREW_DIR/Formula/terraform.rb"

echo "Replacing from 'url' on first instance of that string in file (the url of the MacOS terraform tar.gz file)"
# Need to escape those slashes since we're putting it into a sed
NEW_URL_LINE="$(echo "url \"$URL\"" | sed 's/\//\\\//g')"
echo "NEW_URL_LINE=$NEW_URL_LINE"
sed -i "0,/url.*/s//$NEW_URL_LINE/" "$HOMEBREW_DIR/Formula/terraform.rb"
