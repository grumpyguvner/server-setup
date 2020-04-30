########################################
### DAILY JOBS TO RUN ON ALL SERVERS ###
########################################

## Fetch the current update server scripts
cd /root

# Daily jobs script
wget -O https://github.com/grumpyguvner/server-setup/blob/master/cron/update_scripts.sh
chmod +x /root/update_scripts.sh

# If update scripts doesn't already exist in cron jobs then add it
grep -qi "update_scripts" $CRON_FILE
if [ $? != 0 ]; then
    echo "Updating cron job to fetch current scripts"
    echo "0 2 * * * /root/update_scripts.sh" >> $CRON_FILE
fi

# Update all packages
apt -y update && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

# Remove unused packages
apt -y autoremove

# Daily reboot
shutdown -r now
