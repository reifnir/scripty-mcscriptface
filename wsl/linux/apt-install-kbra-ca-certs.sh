sudo apt-get update
sudo apt-get install ca-certificates curl lsb-release gnupg -y

sudo mkdir /usr/local/share/ca-certificates/kbra
sudo cp /mnt/c/dev/kbra-certificate-authorities/* /usr/local/share/ca-certificates/kbra
sudo chmod 755 /usr/local/share/ca-certificates/kbra
sudo chmod 644 /usr/local/share/ca-certificates/kbra/*
sudo update-ca-certificates
