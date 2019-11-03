#/bin/sh

# s111111 - Service account
# p222222 - System Patching Service Account
# u333333 - Jim Andreasen
# u444444 - Chris Breish
ADMINS=(s111111 p222222 u333333 u444444)
DOMAIN="REIFNIR"

QUEST_INSTALLED=0
if [ -d "/etc/opt/quest" ]; then
  QUEST_INSTALLED=1
fi

for ADMIN in ${ADMINS[*]}; do
  if [ $QUEST_INSTALLED == 1 ]; then
    echo "*** Adding $ADMIN to users able to log in"
    sudo sed -i "/$DOMAIN\\\\$ADMIN/d" /etc/opt/quest/vas/users.allow
    echo "$DOMAIN\\$ADMIN" | sudo tee --append /etc/opt/quest/vas/users.allow > /dev/null
  fi

  echo "*** Adding $ADMIN to sudoers"
  sudo sed -i "/$ADMIN/d" /etc/sudoers
  echo "$ADMIN ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers > /dev/null
done

if [ $QUEST_INSTALLED == 1 ]; then
#flush users so that users can 
  sudo /opt/quest/bin/vastool flush
fi
