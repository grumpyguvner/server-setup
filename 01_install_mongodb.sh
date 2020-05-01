#! /bin/bash

MONGODB="4.2"

# mongo keys
curl -sSL https://www.mongodb.org/static/pgp/server-${MONGODB}.asc 2>&1 | sudo apt-key add
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/$MONGODB multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB.list

# install mongodb
apt-get update
apt-get -q -y install mongodb-org

# update firewall rules to allow traffic on local and private network (default is already set to deny on public network)
ufw allow in on lo to any port 27017
ufw allow in on eth1 to any port 27017
ufw --force enable

# update mongo config to allow external connections (limited by firewall above)
sed -i 's/127.0.0.1/"*"/g' /etc/mongod.conf

# restart mongo and set to start on reboot
service mongod restart
systemctl enable mongod.service