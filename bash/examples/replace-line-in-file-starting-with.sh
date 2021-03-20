#/bin/bash

SOME_EXISTING_FILE="/etc/some/file"

# Useful when you have a SINGLE line in a config file that you want removed if part of it exists and replace with somethign else
# Ex: file containing line 'export X="yourface" and you want to change the value of what X is set to'
#   replace-line-in-file-containing /etc/sudoers jim "jim ALL=(ALL) NOPASSWD:ALL"
function replace-line-in-file-containing() {
  FILE_PATH="$1"
  STARTS_WITH="$2"
  REPLACEMENT="$3"

  >&2 echo "Removing all lines that begin with '$STARTS_WITH' from file '$FILE_PATH'..."
  sudo sed -i "/$STARTS_WITH/d" "$FILE_PATH"

  >&2 echo "Appending '$REPLACEMENT' to the end of file '$FILE_PATH'..."
  echo "$REPLACEMENT" | sudo tee --append "$FILE_PATH" > /dev/null
}
