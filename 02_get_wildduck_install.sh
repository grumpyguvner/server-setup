#! /bin/bash

# This script downloads all the installation files.

if [ -d "/root/wildduck_install" ]; then
  echo -e "Removing existing install folder"
  rm -rf /root/wildduck_install
fi

mkdir /root/wildduck_install && cd /root/wildduck_install

wget -O - https://raw.githubusercontent.com/nodemailer/wildduck/master/setup/get_install.sh | bash

chmod +x install.sh
