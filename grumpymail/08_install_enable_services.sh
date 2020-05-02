#! /bin/bash

OURNAME=08_install_enable_services.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

NODE_PATH=`command -v node`
SYSTEMCTL_PATH=`command -v systemctl`

SRS_SECRET=`pwgen 12 -1`
DKIM_SECRET=`pwgen 12 -1`
ZONEMTA_SECRET=`pwgen 12 -1`
DKIM_SELECTOR=`$NODE_PATH -e 'console.log(Date().toString().substr(4, 3).toLowerCase() + new Date().getFullYear())'`

systemctl enable redis-server.service

echo -e "\n-- These are the installed and required programs:"
node -v
redis-server -v
mongod --version
echo "HOSTNAME: $HOSTNAME"

echo -e "-- Installing ${RED}npm globally${NC} (workaround)"
# See issue https://github.com/nodemailer/grumpymail/issues/82
npm install npm -g

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
