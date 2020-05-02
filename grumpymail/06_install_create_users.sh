#! /bin/bash

OURNAME=06_install_create_users.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

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

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"