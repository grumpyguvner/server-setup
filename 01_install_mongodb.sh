#! /bin/bash

MONGODB="4.2"

# mongo keys
wget -qO- https://www.mongodb.org/static/pgp/server-${MONGODB}.asc | sudo apt-key add
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/$MONGODB multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB.list

# install mongodb
apt-get update
apt-get -q -y install mongodb-org

systemctl enable mongod.service