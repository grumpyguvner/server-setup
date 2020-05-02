#! /bin/bash

OURNAME=12_install_grumpymail_webmail.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

#### WWW ####
####
# clear previous install
if [ -f "/etc/systemd/system/webmail.service" ]
then
    systemctl stop webmail || true
    systemctl disable webmail || true
    rm -rf /etc/systemd/system/webmail.service
fi
rm -rf /var/opt/webmail.git
rm -rf /opt/webmail

# fresh install
cd /var/opt
git clone --bare git://github.com/grumpyguvner/webmail.git

# create update hook so we can later deploy to this location
hook_script_bower webmail
chmod +x /var/opt/webmail.git/hooks/update

# allow deploy user to restart zone-mta service
echo "deploy ALL = (root) NOPASSWD: systemctl restart webmail" >> /etc/sudoers.d/webmail

# checkout files from git to working directory
mkdir -p /opt/webmail
#git --git-dir=/var/opt/webmail.git --work-tree=/opt/webmail checkout "$WEBMAIL_COMMIT"
git --git-dir=/var/opt/webmail.git --work-tree=/opt/webmail checkout
cp /opt/webmail/config/default.toml /etc/grumpymail/webmail.toml

sed -i -e "s/localhost/$HOSTNAME/g;s/999/99/g;s/2587/587/g;s/proxy=false/proxy=true/g;s/domains=.*/domains=[\"$MAILDOMAIN\"]/g" /etc/grumpymail/webmail.toml

cd /opt/webmail

chown -R deploy:deploy /var/opt/webmail.git
chown -R deploy:deploy /opt/webmail

# we need to run bower which reject root
HOME=/home/deploy sudo -u deploy npm install
HOME=/home/deploy sudo -u deploy npm run bowerdeps


echo "d /opt/webmail 0755 deploy deploy" > /etc/tmpfiles.d/zone-mta.conf
log_script "grumpymail-www"

echo '[Unit]
Description=GrumpyMail Webmail
After=grumpymail.service

[Service]
Environment="NODE_ENV=production"
WorkingDirectory=/opt/webmail
ExecStart=/usr/bin/node server.js --config="/etc/grumpymail/webmail.toml"
ExecReload=/bin/kill -HUP $MAINPID
Type=simple
Restart=always
SyslogIdentifier=grumpymail-www

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/webmail.service

systemctl enable webmail.service

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
