########################################
### DAILY JOBS TO RUN ON ALL SERVERS ###
########################################

# Update all packages
apt -y update && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

# Remove unused packages
apt -y autoremove

# Daily reboot
shutdown -r now
