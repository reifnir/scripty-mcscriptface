#/bin/bash

ADMINS=(s111111 p222222 u333333 u444444)

for ADMIN in ${ADMINS[*]}; do
  echo "ADMIN=$ADMIN"
done
