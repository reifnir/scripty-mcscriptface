#!/bin/bash -e
TEMP_DIR="$(mktemp -d)"
DEST_DIR="$1"

# Backup stuff you want to save before wiping an installed WSL distro
if [ -z "$DEST_DIR" ]; then
  if [ "`whoami`" == "root" ]; then
    echo "Can't run this script as root unless you pass a specific destination directory (2nd argument)."
    exit 1
  fi

  echo "No destination passed for where the archive should be made. Saving to your Windows Desktop"
  DEST_DIR="$(echo "$(powershell.exe "cd ~/Desktop; wsl pwd")")"
fi

DIR_NAME="$(pwd | awk -F'/' '{print $NF}')"
BACKUP_FILENAME="$DIR_NAME-$(date +"%Y-%m-%dT%H-%M-%S%-z").tar.gz"

echo "Creating archive of directory '`pwd`' to tar '$TEMP_DIR/$BACKUP_FILENAME'..."
# Don't use pwd or the tar will record the full path and you'll have to restore from root AND you'll need to have the same username next time
RESULTS="$(tar -czvf "$TEMP_DIR/$BACKUP_FILENAME" .)"

FILES_BACKED_UP="$(echo "$RESULTS" | wc -l)"
echo "$FILES_BACKED_UP files backed up"
echo "(If errors occurred during backup, the script would have exited and shown errors already)"

echo "Moving archive '$BACKUP_FILENAME' to '$DEST_DIR'..."
mv "$TEMP_DIR/$BACKUP_FILENAME" "$DEST_DIR"
