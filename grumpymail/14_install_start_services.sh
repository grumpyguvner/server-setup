#! /bin/bash

OURNAME=14_install_start_services.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

# Run tmpfiles definitions to ensure required directories/files
systemd-tmpfiles --create --remove

# Restart rsyslog for the changes to take effect
systemctl restart rsyslog

# update reload script for future updates
echo "#!/bin/bash
systemctl reload nginx
systemctl reload grumpymail
systemctl restart zone-mta
systemctl restart haraka
systemctl restart webmail" > /usr/local/bin/reload-services.sh
chmod +x /usr/local/bin/reload-services.sh

### start services ####

systemctl start mongod
systemctl start grumpymail
systemctl start haraka
systemctl start zone-mta
systemctl start webmail
systemctl reload nginx

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
