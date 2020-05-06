#! /bin/bash

# make sure the install script is started here
OURNAME=03_install_zmta-webadmin.sh
INSTALLDIR=`pwd`
PUBLIC_IP=`curl -s https://api.ipify.org`
WEBADMIN_COMMIT="a69aec12f529d1142f6f4c0a6c2b9f993f9b4a50"

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

echo -e "\n-- Fetching Global Functions & Variables Script --"
wget -O 00_install_global_functions_variables.sh https://raw.githubusercontent.com/nodemailer/wildduck/master/setup/00_install_global_functions_variables.sh
echo -e "\n-- Continuing with install --"
source "$INSTALLDIR/00_install_global_functions_variables.sh"

# Ask for admin password
read -s -p "Enter Admin Password: " ADMINPASS

#### WWW ####
####
# clear previous install
if [ -f "/etc/systemd/system/zmta-webadmin.service" ]
then
    $SYSTEMCTL_PATH stop zmta-webadmin || true
    $SYSTEMCTL_PATH disable zmta-webadmin || true
    rm -rf /etc/systemd/system/zmta-webadmin.service
fi
rm -rf /var/opt/zmta-webadmin.git
rm -rf /opt/zmta-webadmin

# fresh install
cd /var/opt
git clone --bare git://github.com/zone-eu/zmta-webadmin.git

# create update hook so we can later deploy to this location
hook_script zmta-webadmin
chmod +x /var/opt/zmta-webadmin.git/hooks/update

# allow deploy user to restart zone-mta service
echo "deploy ALL = (root) NOPASSWD: $SYSTEMCTL_PATH restart zmta-webadmin" >> /etc/sudoers.d/zmta-webadmin

# checkout files from git to working directory
mkdir -p /opt/zmta-webadmin
git --git-dir=/var/opt/zmta-webadmin.git --work-tree=/opt/zmta-webadmin checkout "$WEBADMIN_COMMIT"
cp /opt/zmta-webadmin/config/default.toml /etc/wildduck/zmta-webadmin.toml

sed -i -e "s/127.0.0.1:27017/10.131.124.127:27017/g;s/secretpass/$ADMINPASS/g" /etc/wildduck/zmta-webadmin.toml

cd /opt/zmta-webadmin

chown -R deploy:deploy /var/opt/zmta-webadmin.git
chown -R deploy:deploy /opt/zmta-webadmin

# install package
HOME=/home/deploy sudo -u deploy npm install


echo "d /opt/zmta-webadmin 0755 deploy deploy" > /etc/tmpfiles.d/zone-mta.conf
log_script "zmta-webadmin"

echo '[Unit]
Description=ZoneMTA WebAdmin
After=wildduck.service

[Service]
Environment="NODE_ENV=production"
WorkingDirectory=/opt/zmta-webadmin
ExecStart=/usr/bin/node server.js --config="/etc/wildduck/zmta-webadmin.toml"
ExecReload=/bin/kill -HUP $MAINPID
Type=simple
Restart=always
SyslogIdentifier=zmta-webadmin

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/zmta-webadmin.service

$SYSTEMCTL_PATH enable zmta-webadmin.service

echo -e "\n-- Removing Global Functions & Variables Script --"
rm "$INSTALLDIR/00_install_global_functions_variables.sh"

echo -e "Add following to nginx config file:
    # ZoneMTA Queue Admin Tool
    location /queueadmin {
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header HOST \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:8082;
        proxy_redirect off;
    }
"