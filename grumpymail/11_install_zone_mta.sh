#! /bin/bash

OURNAME=11_install_zone_mta.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"


#### ZoneMTA ####

# clear previous install
if [ -f "/etc/systemd/system/zone-mta.service" ]
then
    systemctl stop zone-mta || true
    systemctl disable zone-mta || true
    rm -rf /etc/systemd/system/zone-mta.service
fi
rm -rf /var/opt/zone-mta.git
rm -rf /var/opt/zonemta-grumpymail.git
rm -rf /opt/zone-mta
rm -rf /etc/zone-mta

# fresh install
cd /var/opt
git clone --bare git://github.com/zone-eu/zone-mta-template.git zone-mta.git
git clone --bare git://github.com/grumpyguvner/zonemta-grumpymail.git

# create update hooks so we can later deploy to this location
hook_script zone-mta
echo "#!/bin/bash
git --git-dir=/var/opt/zonemta-grumpymail.git --work-tree=/opt/zone-mta/plugins/grumpymail checkout "\$3" -f
cd /opt/zone-mta/plugins/grumpymail
rm -rf package-lock.json
npm install --production --progress=false
sudo systemctl restart zone-mta || echo \"Failed restarting service\"" > "/var/opt/zonemta-grumpymail.git/hooks/update"
chmod +x "/var/opt/zonemta-grumpymail.git/hooks/update"

# allow deploy user to restart zone-mta service
echo "deploy ALL = (root) NOPASSWD: systemctl restart zone-mta" >> /etc/sudoers.d/zone-mta

# checkout files from git to working directory
mkdir -p /opt/zone-mta
#git --git-dir=/var/opt/zone-mta.git --work-tree=/opt/zone-mta checkout "$ZONEMTA_COMMIT"
git --git-dir=/var/opt/zone-mta.git --work-tree=/opt/zone-mta checkout

mkdir -p /opt/zone-mta/plugins/grumpymail
#git --git-dir=/var/opt/zonemta-grumpymail.git --work-tree=/opt/zone-mta/plugins/grumpymail checkout "$GRUMPYMAIL_ZONEMTA_COMMIT"
git --git-dir=/var/opt/zonemta-grumpymail.git --work-tree=/opt/zone-mta/plugins/grumpymail checkout

cp -r /opt/zone-mta/config /etc/zone-mta
sed -i -e 's/port=2525/port=587/g;s/host="127.0.0.1"/host="0.0.0.0"/g;s/authentication=false/authentication=true/g' /etc/zone-mta/interfaces/feeder.toml
rm -rf /etc/zone-mta/plugins/dkim.toml
echo '# @include "/etc/grumpymail/dbs.toml"' > /etc/zone-mta/dbs-production.toml
echo 'user="grumpymail"
group="grumpymail"' | cat - /etc/zone-mta/zonemta.toml > temp && mv temp /etc/zone-mta/zonemta.toml

sed -i -e "s/key=/#key=/g;s/cert=/#cert=/g" /etc/zone-mta/interfaces/feeder.toml
echo '# @include "../../grumpymail/tls.toml"' >> /etc/zone-mta/interfaces/feeder.toml

echo "[[default]]
address=\"0.0.0.0\"
name=\"$HOSTNAME\"" > /etc/zone-mta/pools.toml

echo "[\"modules/zonemta-loop-breaker\"]
enabled=\"sender\"
secret=\"$ZONEMTA_SECRET\"
algo=\"md5\"" > /etc/zone-mta/plugins/loop-breaker.toml

echo "[grumpymail]
enabled=[\"receiver\", \"sender\"]

# which interfaces this plugin applies to
interfaces=[\"feeder\"]

# optional hostname to be used in headers
# defaults to os.hostname()
hostname=\"$HOSTNAME\"

# How long to keep auth records in log
authlogExpireDays=30

# SRS settings for forwarded emails

[grumpymail.srs]
    # Handle rewriting of forwarded emails
    enabled=true
    # SRS secret value. Must be the same as in the MX side
    secret=\"$SRS_SECRET\"
    # SRS domain, must resolve back to MX
    rewriteDomain=\"$MAILDOMAIN\"

[grumpymail.dkim]
# share config with GrumpyMail installation
# @include \"/etc/grumpymail/dkim.toml\"
" > /etc/zone-mta/plugins/grumpymail.toml

cd /opt/zone-mta/keys
# Many registrar limits dns TXT fields to 255 char. 1024bit is almost too long:-\
openssl genrsa -out "$MAILDOMAIN-dkim.pem" 1024
chmod 400 "$MAILDOMAIN-dkim.pem"
openssl rsa -in "$MAILDOMAIN-dkim.pem" -out "$MAILDOMAIN-dkim.cert" -pubout
DKIM_DNS="v=DKIM1;k=rsa;p=$(grep -v -e '^-' $MAILDOMAIN-dkim.cert | tr -d "\n")"

DKIM_JSON=`DOMAIN="$MAILDOMAIN" SELECTOR="$DKIM_SELECTOR" node -e 'console.log(JSON.stringify({
  domain: process.env.DOMAIN,
  selector: process.env.SELECTOR,
  description: "Default DKIM key for "+process.env.DOMAIN,
  privateKey: fs.readFileSync("/opt/zone-mta/keys/"+process.env.DOMAIN+"-dkim.pem", "UTF-8")
}))'`

cd /opt/zone-mta
npm install --unsafe-perm --production

cd /opt/zone-mta/plugins/grumpymail
npm install --unsafe-perm --production

chown -R deploy:deploy /var/opt/zone-mta.git
chown -R deploy:deploy /var/opt/zonemta-grumpymail.git
chown -R deploy:deploy /opt/zone-mta
chown -R grumpymail:grumpymail /etc/zone-mta

# Ensure required files and permissions
echo "d /opt/zone-mta 0755 deploy deploy
d /etc/zone-mta 0755 grumpymail grumpymail" > /etc/tmpfiles.d/zone-mta.conf
log_script "zone-mta"

echo '[Unit]
Description=Zone Mail Transport Agent
Conflicts=sendmail.service exim.service postfix.service
After=redis.service

[Service]
Environment="NODE_ENV=production"
WorkingDirectory=/opt/zone-mta
ExecStart=/usr/bin/node index.js --config="/etc/zone-mta/zonemta.toml"
ExecReload=/bin/kill -HUP $MAINPID
Type=simple
Restart=always
SyslogIdentifier=zone-mta

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/zone-mta.service

systemctl enable zone-mta.service

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
