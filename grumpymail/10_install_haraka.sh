#! /bin/bash

OURNAME=10_install_haraka.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"



####### HARAKA #######

# clear previous install
if [ -f "/etc/systemd/system/haraka.service" ]
then
    systemctl stop haraka || true
    systemctl disable haraka || true
    rm -rf /etc/systemd/system/haraka.service
fi
rm -rf /var/opt/haraka-plugin-grumpymail.git
rm -rf /opt/haraka

# fresh install
cd /var/opt
git clone --bare git://github.com/grumpyguvner/haraka-plugin-grumpymail.git
echo "#!/bin/bash
git --git-dir=/var/opt/haraka-plugin-grumpymail.git --work-tree=/opt/haraka/plugins/grumpymail checkout "\$3" -f
cd /opt/haraka/plugins/grumpymail
rm -rf package-lock.json
npm install --production --progress=false
sudo systemctl restart haraka || echo \"Failed restarting service\"" > "/var/opt/haraka-plugin-grumpymail.git/hooks/update"
chmod +x "/var/opt/haraka-plugin-grumpymail.git/hooks/update"

# allow deploy user to restart grumpymail service
echo "deploy ALL = (root) NOPASSWD: systemctl restart haraka" >> /etc/sudoers.d/grumpymail

cd
npm install --unsafe-perm -g Haraka@$HARAKA_VERSION
haraka -i /opt/haraka
cd /opt/haraka
npm install --unsafe-perm --save haraka-plugin-rspamd Haraka@$HARAKA_VERSION

# Haraka GrumpyMail plugin. Install as separate repo as it can be edited more easily later
mkdir -p plugins/grumpymail
#git --git-dir=/var/opt/haraka-plugin-grumpymail.git --work-tree=/opt/haraka/plugins/grumpymail checkout "$GRUMPYMAIL_HARAKA_COMMIT"
git --git-dir=/var/opt/haraka-plugin-grumpymail.git --work-tree=/opt/haraka/plugins/grumpymail checkout

cd plugins/grumpymail
npm install --unsafe-perm --production --progress=false

cd /opt/haraka
mv config/plugins config/plugins.bak

echo "26214400" > config/databytes
echo "$HOSTNAME" > config/me
echo "GrumpyMail MX" > config/smtpgreeting

echo "spf
dkim_verify

## ClamAV is disabled by default. Make sure freshclam has updated all
## virus definitions and clamav-daemon has successfully started before
## enabling it.
#clamd

rspamd
tls

# GrumpyMail plugin handles recipient checking and queueing
grumpymail" > config/plugins

echo "key=/etc/grumpymail/certs/privkey.pem
cert=/etc/grumpymail/certs/fullchain.pem" > config/tls.ini

echo 'host = localhost
port = 11333
add_headers = always
[dkim]
enabled = true
[header]
bar = X-Rspamd-Bar
report = X-Rspamd-Report
score = X-Rspamd-Score
spam = X-Rspamd-Spam
[check]
authenticated=true
private_ip=true
[reject]
spam = false
[soft_reject]
enabled = true
[rmilter_headers]
enabled = true
[spambar]
positive = +
negative = -
neutral = /' > config/rspamd.ini

echo 'clamd_socket = /var/run/clamav/clamd.ctl
[reject]
virus=true
error=false' > config/clamd.ini

cp plugins/grumpymail/config/grumpymail.yaml config/grumpymail.yaml
sed -i -e "s/secret value/$SRS_SECRET/g" config/grumpymail.yaml

# Ensure required files and permissions
echo "d /opt/haraka 0755 deploy deploy" > /etc/tmpfiles.d/haraka.conf
log_script "haraka"

echo '[Unit]
Description=Haraka MX Server
After=redis.service

[Service]
Environment="NODE_ENV=production"
WorkingDirectory=/opt/haraka
ExecStart=/usr/bin/node ./node_modules/.bin/haraka -c .
Type=simple
Restart=always
SyslogIdentifier=haraka

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/haraka.service

echo 'user=grumpymail
group=grumpymail' >> config/smtp.ini

chown -R deploy:deploy /opt/haraka
chown -R deploy:deploy /var/opt/haraka-plugin-grumpymail.git

# ensure queue folder for Haraka
mkdir -p /opt/haraka/queue
chown -R grumpymail:grumpymail /opt/haraka/queue

systemctl enable haraka.service

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
