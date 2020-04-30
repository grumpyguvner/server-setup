#!/bin/bash
set -euo pipefail

if [ `id -u` -ne 0 ]; then
    echo "This script can only be run as root! Exiting.."
    exit 1
fi
if [ $# -eq 0 ]
  then
    echo "Please use username as parameter, use \`id -un\` to use your current username which will be used to create a new user and grant sudo privileges! Exiting.."
    exit 1
fi
if id "$1" >/dev/null 2>&1; then
    echo "The username $1 already exists on this server, this script is meant to be installed on a freshly provisioned server! Exiting.."
    exit 1
fi

########################
### SCRIPT VARIABLES ###
########################

# Name of the user to create and grant sudo privileges
USERNAME=$1

# Filename used for creating cron jobs
CRON_FILE="/var/spool/cron/root"

# Install required packackages
apt get -q -y wget
apt clean

# Whether to copy over the root user's `authorized_keys` file to the new sudo
# user.
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

# Additional public keys to add to the new sudo user
# OTHER_PUBLIC_KEYS_TO_ADD=(
#     "ssh-rsa AAAAB..."
#     "ssh-rsa AAAAB..."
# )
OTHER_PUBLIC_KEYS_TO_ADD=(
)

####################
### SCRIPT LOGIC ###
####################

# Add sudo user and grant privileges
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"

# Check whether the root account has a real password set
encrypted_root_pw="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

if [ "${encrypted_root_pw}" != "*" ]; then
    # Transfer auto-generated root password to user if present
    # and lock the root account to password-based access
    echo "${USERNAME}:${encrypted_root_pw}" | chpasswd --encrypted
    passwd --lock root
else
    # Delete invalid password for user if using keys so that a new password
    # can be set without providing a previous value
    passwd --delete "${USERNAME}"
fi

# Expire the sudo user's password immediately to force a change
chage --lastday 0 "${USERNAME}"

# Create SSH directory for sudo user
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
fi

# Add additional provided public keys
for pub_key in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
    echo "${pub_key}" >> "${home_directory}/.ssh/authorized_keys"
done

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

# Add exception for SSH and then enable UFW firewall
ufw allow OpenSSH
ufw --force enable

#############################
### Digital Ocean Metrics ###
#############################

# Uninstall the legacy metrics agent
apt purge -y do-agent

# Install the current metrics agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | bash

########################
###    CRON JOBS     ###
########################

# Create a cron job to run daily taks
if [ ! -f $CRON_FILE ]; then
    echo "cron file for root doesn't exist, creating.."
    touch $CRON_FILE
    /usr/bin/crontab $CRON_FILE
fi
## Fetch the current daily job scripts
cd /root
wget 
if [ ! -f /root/daily_jobs.sh ]; then
    echo "Daily jobs script doesn't exist, creating.."
    touch /root/daily_jobs.sh
    chmod +x /root/daily_jobs.sh
fi
for i in "${DAILY_JOBS[@]}"
do
   echo "$i" >> /root/daily_jobs.sh
done
# If daily jobs script doesn't already exist in cron jobs then add ot
grep -qi "daily_jobs" $CRON_FILE
if [ $? != 0 ]; then
    echo "Updating cron job for daily jobs"
    echo "0 1 * * * /root/update_daily_jobs.sh" >> $CRON_FILE
    echo "0 15 * * * /root/daily_jobs.sh" >> $CRON_FILE
fi
