# Setup Windows Subsystem for Linux 2

## Worried about losing your data?

Deleting these ahead of time speeds up the backup and restore process considerably if you have a lot of local projects.

Get rid of those bloated .terraform directories
```
DIR_NAME=".terraform"
find . -name "$DIR_NAME" | xargs -n1 rm -rf
```

Back up an entire directory named `dev` (for example) in the current working directory and copy it to somewhere on your Windows drive.

## Backup a folder

```bash
sudo tar -czvf "dev-$(date +"%Y-%m-%d").tar.gz" ./dev
```

## Restore that folder
```bash
tar -xzvf ./dev-2022-07-01.tar.gz .
```
