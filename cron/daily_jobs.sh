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
    echo "0 2 * * * /root/update_scripts.sh" >> $CRON_FILE
    crontab $CRON_FILE
fi

# Update all packages
apt-get -y update && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

# Remove unused packages
apt-get -y autoremove

# Daily reboot
shutdown -r now
