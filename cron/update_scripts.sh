#!/usr/bin/env bash
set -e

############################################
### UPDATE SCRIPTS TO RUN ON ALL SERVERS ###
############################################

# Filename used for creating cron jobs
CRON_FILE="/var/spool/cron/root"

## Fetch the current server scripts
cd /root

# Daily jobs script
curl -sSL -o daily_jobs.sh https://raw.githubusercontent.com/grumpyguvner/server-setup/master/cron/daily_jobs.sh
chmod +x /root/daily_jobs.sh

# If daily jobs script doesn't already exist in cron jobs then add it
grep -qi "daily_jobs" $CRON_FILE
if [ $? != 0 ]; then
    echo "Creating cron job for daily jobs"
    echo "15 1 * * * /root/daily_jobs.sh" >> $CRON_FILE
    crontab -u root $CRON_FILE
fi
