#! /bin/bash

OURNAME=05_install_packages.sh

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

# install nginx
apt-get update
apt-get -q -y install pwgen git ufw build-essential libssl-dev dnsutils python software-properties-common nginx wget nodejs redis-server clamav clamav-daemon

# rspamd
apt-get -q -y --no-install-recommends install rspamd
apt-get clean

# DMARC policy=reject rules
echo 'actions = {
    quarantine = "add_header";
    reject = "reject";
}' > /etc/rspamd/override.d/dmarc.conf

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
