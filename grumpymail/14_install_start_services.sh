#! /bin/bash

OURNAME=14_install_start_services.sh

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

# Run tmpfiles definitions to ensure required directories/files
systemd-tmpfiles --create --remove

# Restart rsyslog for the changes to take effect
systemctl restart rsyslog

# update reload script for future updates
echo "#!/bin/bash
$SYSTEMCTL_PATH reload nginx
$SYSTEMCTL_PATH reload grumpymail
$SYSTEMCTL_PATH restart zone-mta
$SYSTEMCTL_PATH restart haraka
$SYSTEMCTL_PATH restart webmail" > /usr/local/bin/reload-services.sh
chmod +x /usr/local/bin/reload-services.sh

### start services ####

$SYSTEMCTL_PATH start mongod
$SYSTEMCTL_PATH start grumpymail
$SYSTEMCTL_PATH start haraka
$SYSTEMCTL_PATH start zone-mta
$SYSTEMCTL_PATH start webmail
$SYSTEMCTL_PATH reload nginx

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
