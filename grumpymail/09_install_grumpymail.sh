#! /bin/bash

OURNAME=09_install_grumpymail.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

####### GRUMPY MAIL #######

# clear previous install
if [ -f "/etc/systemd/system/grumpymail.service" ]
then
    systemctl stop grumpymail || true
    systemctl disable grumpymail || true
    rm -rf /etc/systemd/system/grumpymail.service
fi
rm -rf /var/opt/grumpymail.git
rm -rf /opt/grumpymail

# fresh install
cd /var/opt
git clone --bare git://github.com/grumpyguvner/grumpymail.git

# create update hook so we can later deploy to this location
hook_script grumpymail

# allow deploy user to restart grumpymail service
echo "deploy ALL = (root) NOPASSWD: systemctl restart grumpymail" >> /etc/sudoers.d/grumpymail

# checkout files from git to working directory
mkdir -p /opt/grumpymail
#always get latest for this repo when testing
echo -e "\n-- Gettting latest commit to working dir --"
git --git-dir=/var/opt/grumpymail.git --work-tree=/opt/grumpymail checkout
#git --git-dir=/var/opt/grumpymail.git --work-tree=/opt/grumpymail checkout "$GRUMPYMAIL_COMMIT"
cp -r /opt/grumpymail/config /etc/grumpymail
mv /etc/grumpymail/default.toml /etc/grumpymail/grumpymail.toml

echo 'cert="/etc/grumpymail/certs/fullchain.pem"
key="/etc/grumpymail/certs/privkey.pem"' > /etc/grumpymail/tls.toml

# enable example message
#sed -i -e 's/"disabled": true/"disabled": false/g' /opt/grumpymail/emails/00-example.json

# update ports
sed -i -e "s/999/99/g;s/localhost/$HOSTNAME/g" /etc/grumpymail/imap.toml
sed -i -e "s/999/99/g;s/localhost/$HOSTNAME/g" /etc/grumpymail/pop3.toml

echo "enabled=true
port=24
disableSTARTTLS=true" > /etc/grumpymail/lmtp.toml

# make sure that DKIM keys are not stored to database as cleartext
#echo "secret=\"$DKIM_SECRET\"
#cipher=\"aes192\"" >> /etc/grumpymail/dkim.toml

echo "user=\"grumpymail\"
group=\"grumpymail\"
emailDomain=\"$MAILDOMAIN\"" | cat - /etc/grumpymail/grumpymail.toml > temp && mv temp /etc/grumpymail/grumpymail.toml

sed -i -e "s/localhost:3000/$HOSTNAME/g;s/localhost/$HOSTNAME/g;s/2587/587/g" /etc/grumpymail/grumpymail.toml

cd /opt/grumpymail
npm install --unsafe-perm --production

chown -R deploy:deploy /var/opt/grumpymail.git
chown -R deploy:deploy /opt/grumpymail

echo "d /opt/grumpymail 0755 deploy deploy
d /etc/grumpymail 0755 grumpymail grumpymail" > /etc/tmpfiles.d/zone-mta.conf
log_script "grumpymail-server"

echo "[Unit]
Description=GrumpyMail Mail Server
Conflicts=cyrus.service dovecot.service
After=redis.service

[Service]
Environment=\"NODE_ENV=production\"
WorkingDirectory=/opt/grumpymail
ExecStart=$NODE_PATH server.js --config=\"/etc/grumpymail/grumpymail.toml\"
ExecReload=/bin/kill -HUP \$MAINPID
Type=simple
Restart=always
SyslogIdentifier=grumpymail-server

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/grumpymail.service

systemctl enable grumpymail.service

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
