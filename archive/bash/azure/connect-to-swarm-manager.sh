RESOURCE_GROUP="rg-doc-test"
SUBSCRIPTION="KBRA-Test+Prod"
VM_NAME_LIKE="SwarmManager"

getMyIP() {
    local _ip _myip _line _nl=$'\n'
    while IFS=$': \t' read -a _line ;do
        [ -z "${_line%inet}" ] &&
           _ip=${_line[${#_line[1]}>4?1:2]} &&
           [ "${_ip#127.0.0.1}" ] && _myip=$_ip
      done< <(LANG=C /sbin/ifconfig)
    printf ${1+-v} $1 "%s${_nl:0:$[${#1}>0?0:1]}" $_myip
}

getDockerManagerIpAddress() {
    ARRAY_OF_IP_ADDRESSES=$(az vm list-ip-addresses \
        --subscription=$SUBSCRIPTION \
        --resource-group $RESOURCE_GROUP \
        --query "[?contains(virtualMachine.name,'$VM_NAME_LIKE')].virtualMachine.network.privateIpAddresses[]" \
        --out tsv
    )

    MACHINE_INDEX=0
    REACHED_MANAGER='false'
    for IP in ${ARRAY_OF_IP_ADDRESSES[*]}; do
        #echo "Attempting to connect to Docker manager $MACHINE_INDEX..."
        VERSION=$(docker --host "$IP" version) #Only want this for its error exit code
        # Failure test
        VERSION=$(eval testing-with-non-existant-command)
        RESULT=$?
        if [ "$RESULT" == 0 ] ; then
            #echo "Can reach host: $IP, exiting loop..."
            echo $IP
            REACHED_MANAGER='true'
            break
        else
            >&2 echo "Cannot reach host: $IP, moving on"
        fi

        MACHINE_INDEX=$(($MACHINE_INDEX+1))
    done

    # Exiting the script with an error condition if no host was connectable
    if [ ! $REACHED_MANAGER == 'true' ] ; then
        >&2 echo "Unable to reach any of the Docker managers"
        exit 1
    fi
}

MY_IP=$(getMyIP)
DOCKER_MANAGER_IP=$(getDockerManagerIpAddress)

echo "MY_IP = $MY_IP"
echo "DOCKER_MANAGER_IP = $DOCKER_MANAGER_IP"
docker --host "$DOCKER_MANAGER_IP" node


