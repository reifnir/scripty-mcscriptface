sudo systemctl stop ipremote.service
sudo rm /apps/IPsoft/IPremote/var/IPremoted.pid
sudo systemctl start ipremote.service
sudo systemctl status ipremote.service
