#!/bin/bash
#====================================
# Requires the following commands
# - curl
# - jq
#====================================
set -e

VERSION="$1"

if [ -z "$VERSION" ]
then
  echo "Terraform version argument was not passed."
  echo "Checking for latest released version..."
  VERSION="`curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq '.current_version' -r`"
  echo "VERSION='$VERSION'"
else
  echo "Terraform version argument passed was '$VERSION'."
fi
