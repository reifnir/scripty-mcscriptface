# Setup Windows Subsystem for Linux 2

## Verify WSL2 is installed

If you can run the following command without error:

```PowerShell
wsl --help
```

Then either WSL 1 or 2 is installed.

If you can run the following command and you see a `VERSION` column, then WSL2 is installed:

```PowerShell
wsl -l -v
```

## Install the Ubuntu 22.04 LTS

Ubuntu 22.04 is the latest version of to be released by Canonical as a WSL distro (as of 7/9/2022).

### Windows 11 (with access to Windows Store)

If you have access to the Windows Store and are using Windows 11, installing Ubuntu 22.04 LTS in WSL is as simple as running a simple line of code:

```PowerShell
winget install --name "Ubuntu 22.04 LTS"
```

### Windows 11 (without access to Windows Store)

Execute the `Install-Ubuntu-22.04-LTS.ps1` script in this repo. _It takes considerably longer._


From CMD or PowerShell, run the following:

```PowerShell
wsl --list --version
```

If WSL2 is installed correctly you'll see something like this if you don't have a distro installed.
```
  NAME                   STATE           VERSION
* docker-desktop         Stopped         2
  docker-desktop-data    Stopped         2
```

## Install dev tools into WSL

Just run the `setup-ubuntu-22.04.sh` located in this repo. In most circumstances you can run it multiple times. There are a few edge cases I haven't tested. If you ever run into problems, you can reset or uninstall/reinstall Ubuntu 22.04 and go from scratch. (Don't forget to backup your working directory!)

- Upgrading an older installation of Ubuntu 20.04 with the new script
- Changing node version

From Windows PowerShell:
```PowerShell
PS C:\dev\scripty-mcscriptface> wsl ./wsl/setup-ubuntu-22.04.sh
Starting: 2022-07-10T12:07:56-04:00
Windows username: reifn
  Linux username: reifn
Setting up
[sudo] password for reifn: 
...
```

From WSL itself:
```bash
reifn@reifnir-r7-2700:~$ /mnt/c/dev/scripty-mcscriptface/wsl/setup-ubuntu-22.04.sh
Starting: 2022-07-10T12:08:59-04:00
Windows username: reifn
  Linux username: reifn
Setting up
[sudo] password for reifn:
...
```

### TroubleshootingTROUBLESHOOTING

If you get an error saying that you can't run as root and you didn't kick it off with a `sudo` statement, then `docker-desktop` is probably your default WSL install. You can fix that with:

```PowerShell
PS C:\dev\scripty-mcscriptface> wsl -l -v
  NAME                   STATE           VERSION
  Ubuntu-22.04           Running         2
* docker-desktop         Running         2
  docker-desktop-data    Running         2

PS C:\dev\scripty-mcscriptface> wsl --set-default Ubuntu-22.04

PS C:\dev\scripty-mcscriptface> wsl -l -v
  NAME                   STATE           VERSION
* Ubuntu-22.04           Running         2
  docker-desktop         Running         2
  docker-desktop-data    Running         2
```

### Main

| App/Package | Version     | Apt | Specific Version                                                                                               |   |
|-------------|-------------|-----|----------------------------------------------------------------------------------------------------------------|---|
| .NET 6.0    | latest      | [x] |                                                                                                                |   |
| AWS CLI     | latest (v2) | []  |                                                                                                                |   |
| Azure CLI   | latest      | [x] |                                                                                                                |   |
| Helm        | latest (v3) | [x] |                                                                                                                |   |
| kubectl     | latest      | []  |                                                                                                                |   |
| NodeJS, NPM | latest      | []  | `NODE_VERSION="16"` Look [here](https://github.com/nodesource/distributions#debinstall) for different versions |   |
| PowerShell  | latest      | [x] |                                                                                                                |   |
| Python      | latest (v3) | [x] |                                                                                                                |   |
| Terraform   | latest      | [x] | *Note:* Terraform state is not backward compatible prior to 0.14                                               |   |
| Yarn        | latest      | []  |                                                                                                                |   |

### Misc packages

- jq
- direnv
- ncdu

### Other nice things
<!-- TODO: add this tonight
- **SSH keys**: the default SSH key (`id_rsa` and `id_rsa.pub`) are copied from the Windows host into the Linux ~/.ssh directory.
    * These keys are copied instead of linked because it is impossible to set proper Linux permissions on files hosted on an NTFS partition.
-->
- **sudo without password**: You will no longer need to enter your WSL user password when typing sudo once you're in the shell.

## Backup/Restore

You have better performance and full Linux file permissions if you keep your working directory inside the Linux filesystem rather than the NFS-like translation that happens communicating directly with your `C:\` drive.

The only hassle about that is if you want to wipe your WSL installation. This repo adds a couple of scripts to make that easy.

### Dump binaries before backing up

**Save some time**: Before you backup development working directories, you'll probably want to clear out binaries you can pull down again such as `.terraform`, `node_modules`, `obj`, `bin`, etc. Deleting these ahead of time speeds up the backup and restore process considerably if you have a lot of local projects.

Here's a simple script to help with that (careful, `rm -rf` is a loaded weapon 😅):

```bash
find . -name ".terraform" | xargs -n1 rm -rf
```

You can also use `ncdu` to look for eggregiously large files you don't want backed-up if it's taking too long.

### Backing up

It's pretty easy to backup your from Windows 11 manually using the automatic fileshare (ex: `\\wsl.localhost\Ubuntu-22.04\home\reifn`), but remember that if you copy out and back into one of these, you're going to be replacing any existing the Linux permissions with: owner=root, group=root, permissions=0644 😬.

If you originally installed WSL with this repo, just set your working directory to the one you want to backup and execute the `~/wsl-scripts/backup-current-directory.sh` script. It takes one optional argument for a destination directory (if you don't want the backup moved to your Windows desktop). Backups are in the format `{dir name}-{ISO8601-like timestamp}`. Ex: `dev-2022-07-10T10-42-58-04-00.tar.gz`

Example of script in use:
```bash
reifn@reifnir-r7-2700:~$ cd ~/dev
reifn@reifnir-r7-2700:~/dev$ ~/wsl-scripts/backup-current-directory.sh
No destination passed for where the archive should be made. Saving to your Windows Desktop
Creating archive of directory '/home/reifn/dev' to tar '/tmp/tmp.zCc0E9znhl/dev-2022-07-10T11-28-11-400.tar.gz'...
1250 files backed up
(If errors occurred during backup, the script would have exited and shown errors already)
Moving archive 'dev-2022-07-10T11-28-11-400.tar.gz' to '/mnt/c/Users/reifn/Desktop'...
mv: preserving times for '/mnt/c/Users/reifn/Desktop/dev-2022-07-10T11-28-11-400.tar.gz': Operation not permitted
mv: preserving permissions for ‘/mnt/c/Users/reifn/Desktop/dev-2022-07-10T11-28-11-400.tar.gz’: Operation not permitted
```

### Restore

Restoring from backup is as simple as navigating to the directory whose contents you want restored.

Here's an example:
```bash
mkdir ~/dev
~/wsl-scripts/restore-to-current-directory.sh /mnt/c/Users/reifn/Desktop/dev-2022-07-10T11-28-11-400.tar.gz
```
