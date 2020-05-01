#! /bin/bash

OURNAME=04_install_import_keys.sh

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

# create user for running applications
useradd grumpymail || echo "User grumpymail already exists"

# remove old sudoers file
rm -rf /etc/sudoers.d/grumpymail

# create user for deploying code
useradd deploy || echo "User deploy already exists"

mkdir -p /home/deploy/.ssh
# copy the DO droplet keys to the deploy user
cat /root/.ssh/authorized_keys > /home/deploy/.ssh/authorized_keys
# add your own key to the authorized_keys file
#echo "# Add your public key here" >> /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy

export DEBIAN_FRONTEND=noninteractive

# nodejs
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key 2>&1 | apt-key add -
echo "deb https://deb.nodesource.com/$NODEREPO $CODENAME main" > /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/$NODEREPO $CODENAME main" >> /etc/apt/sources.list.d/nodesource.list

# rspamd
curl -sSL https://rspamd.com/apt-stable/gpg.key 2>&1 | apt-key add -
echo "deb http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list
echo "deb-src http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list
apt-get update

# redis
apt-add-repository -y ppa:chris-lea/redis-server

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
