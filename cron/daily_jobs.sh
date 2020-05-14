#!/usr/bin/env bash
set -e

########################################
### DAILY JOBS TO RUN ON ALL SERVERS ###
########################################

# Filename used for creating cron jobs
CRON_FILE="/var/spool/cron/root"

## Fetch the current update server scripts
cd /root

# Daily jobs script
curl -sSL -o update_scripts.sh https://raw.githubusercontent.com/grumpyguvner/server-setup/master/cron/update_scripts.sh
chmod +x /root/update_scripts.sh

# If update scripts doesn't already exist in cron jobs then add it
grep -qi "update_scripts" $CRON_FILE
if [ $? != 0 ]; then
    echo "Creating cron job to fetch current scripts"
    echo "0 1 * * * /root/update_scripts.sh" >> $CRON_FILE
    crontab -u root $CRON_FILE
fi

patching(){
    # Upgrade all packages
    sudo apt-get update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y;
    # Remove unused packages
    apt-get autoremove =y;
};

patching;

# Daily reboot
/sbin/shutdown -r now
