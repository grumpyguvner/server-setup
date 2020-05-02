#! /bin/bash

OURNAME=06_install_packages.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

# install nginx
apt-get update
apt-get -q -y install pwgen git ufw build-essential libssl-dev dnsutils python software-properties-common nginx nodejs redis-server clamav clamav-daemon

# rspamd
apt-get -q -y --no-install-recommends install rspamd
apt-get clean

# DMARC policy=reject rules
echo 'actions = {
    quarantine = "add_header";
    reject = "reject";
}' > /etc/rspamd/override.d/dmarc.conf

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
