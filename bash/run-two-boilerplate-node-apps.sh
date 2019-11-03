sudo yum install nodejs -y

function setup_node {
    PORT=$1

    if [[ ! $PORT =~ ^[0-9]+$ ]]
    then
        echo "Who are you kidding, you have to pass a port number, ya jerk"
        return 1
    else
        echo "Kicking-off node with at port $PORT"
    fi

    mkdir $PORT

    cat > ./$PORT/app.js <<EOF
    const express = require('express')
    const app = express()

    app.get('*', (req, res) => res.send('Hello World from $(hostname):$PORT!'))

    app.listen($PORT, () => console.log('Example app listening on port $PORT!'))
EOF
    cd $PORT
    npm install express
    cd ..
    nohup node ./$PORT/app.js & > /dev/null

}

sudo pkill node #kill all running node instances
setup_node 8080
setup_node 10244

sudo rm -rf /app
sudo mkdir /app/ui -p
sudo bash -c 'sudo cat << EOF > /app/ui/test
Static file form /app/ui on $(hostname) 
EOF'
