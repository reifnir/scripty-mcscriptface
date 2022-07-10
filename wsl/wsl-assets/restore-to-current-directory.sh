#!/bin/bash -e

# This is a trivial script, but it's helpful to not have to remember which switches were used in making the tar
TAR_TO_RESTORE="$1"

# Backup stuff you want to save before wiping an installed WSL distro
if [ -z "$TAR_TO_RESTORE" ]; then
  echo "Nothing passed into the script. Aborting script."
  exit 1
elif [ ! -f "$TAR_TO_RESTORE" ]; then
  echo "No file found at path '$TAR_TO_RESTORE'. Aborting script."
  exit 1
fi
if [ `pwd` == ~ ]; then
  echo "You're about to restore directly into your home directory!"
    while true; do
      read -p "Are you sure you want to do this? " yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
    done
fi

tar -xzvf "$TAR_TO_RESTORE" .
