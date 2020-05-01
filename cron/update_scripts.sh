############################################
### UPDATE SCRIPTS TO RUN ON ALL SERVERS ###
############################################

## Fetch the current server scripts
cd /root

# Daily jobs script
curl -sSL -o daily_jobs.sh https://github.com/grumpyguvner/server-setup/raw/master/cron/daily_jobs.sh
chmod +x /root/daily_jobs.sh

# If daily jobs script doesn't already exist in cron jobs then add it
grep -qi "daily_jobs" $CRON_FILE
if [ $? != 0 ]; then
    echo "Updating cron job for daily jobs"
    echo "0 15 * * * /root/daily_jobs.sh" >> $CRON_FILE
fi