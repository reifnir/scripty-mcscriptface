#!/bin/bash
#====================================
# Requires the following commands
# - curl
# - unzip
# - jq
# apt update -qq && apt install curl jq unzip -yqqqq
#====================================

set -e

SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}")"
VERSION="$1"

function get-architecture() {
  echo "`uname`" | sed 's/.*/\L&/'
}

function get-platform() {
  case "`uname -m`" in

    x86_64)
      echo "amd64"
      ;;

    i386 | i686)
      echo "386"
      ;;

    aarch64_be | aarch64 | armv8b | armv8l | aarch64_be | aarch64_be)
      echo "arm64"
      ;;

    *)
      >&2 echo "Error Unable to determine platform for 'uname -m' == '`uname -m`'. Exiting script in failure"
      exit 1
      ;;
  esac
}

ARCH="`get-architecture`"
PLATFORM="`get-platform`"

if [ -z "$VERSION" ]
then
  echo "Terraform version argument was not passed to install-terraform.sh"
  echo "Checking for latest released version..."
  VERSION="`curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq '.current_version' -r`"
  echo "VERSION='$VERSION'"
else
  echo "Terraform version argument passed was '$VERSION'."
fi

ZIP_DIR="`mktemp -td terraform-installer-$VERSION-XXXXX`"
ZIP_FILE="$ZIP_DIR/tf.zip"
URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${ARCH}_${PLATFORM}.zip"
echo "Attempting to download Terraform archive to path '$ZIP_FILE' from '$URL'..."
curl -s "$URL" -o "$ZIP_FILE"

echo "Unzipping file '$ZIP_FILE' to '$ZIP_DIR'..."
unzip "$ZIP_FILE" -d "$ZIP_DIR"

echo "Assigning rx permissions to terraform file..."
chmod 555 "$ZIP_DIR/terraform"

echo "Moving terraform executable to /usr/bin/local"
mv "$ZIP_DIR/terraform" "/usr/local/bin/terraform"

echo "Cleaning up temp artifacts..."
rm -rf "$ZIP_DIR"

echo "Exiting $SCRIPT_NAME with success"
