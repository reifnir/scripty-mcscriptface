#!/bin/bash -e
TEMP_DIR="$(mktemp -d)"

DIR_TO_BACKUP="$1"
DEST_DIR="$2"

# Backup stuff you want to save before wiping an installed WSL distro
if [ -z "$DIR_TO_BACKUP" ]; then
  echo "Nothing passed into the script. Cancelling in error."
  exit 1
fi
if [ ! -d "$DIR_TO_BACKUP" ]; then
  echo "'$DIR_TO_BACKUP' doesn't exist. Cancelling in error."
  exit 1
fi

if [ -z "$DEST_DIR" ]; then
  if [ "`whoami`" == "root" ]; then
    echo "Can't run this script as root unless you pass a specific destination directory (2nd argument)."
    exit 1
  fi

  echo "No destination passed for where the archive should be made. Saving to your Windows Desktop"
  DEST_DIR="$(echo "$(powershell.exe "cd ~/Desktop; wsl pwd")")"
fi

DIR_NAME="$(cd "$DIR_TO_BACKUP" && pwd | awk -F'/' '{print $NF}')"
BACKUP_FILENAME="$DIR_NAME-$(date +"%Y-%m-%dT%H:%M:%S%:z").tar.gz"

echo "DIR_NAME=$DIR_NAME"
echo "BACKUP_FILENAME=$BACKUP_FILENAME"

echo "Creating archive of directory '$DIR_TO_BACKUP' to tar '$TEMP_DIR/$BACKUP_FILENAME'..."
RESULTS="$(tar -czvf "$TEMP_DIR/$BACKUP_FILENAME" "$DIR_TO_BACKUP")"
FILES_BACKED_UP="$(echo "$RESULTS" | wc -l)"


echo "Moving archive '$BACKUP_FILENAME' to '$DEST_DIR'..."
mv "$TEMP_DIR/$BACKUP_FILENAME" "$DEST_DIR"
