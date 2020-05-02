#! /bin/bash

OURNAME=03_install_ssl_certs.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

#### SSL CERTS ####

if [ ! -d "/etc/grumpymail/certs" ]; then

    curl https://get.acme.sh 2>&1 | sh

    # vanity script as first run should not restart anything
    echo '#!/bin/bash
    echo "OK"' > /usr/local/bin/reload-services.sh
    chmod +x /usr/local/bin/reload-services.sh

    #/root/.acme.sh/acme.sh --issue --nginx --staging --test \
    /root/.acme.sh/acme.sh --issue --nginx \
        -d "$HOSTNAME" \
        --key-file       /etc/grumpymail/certs/privkey.pem  \
        --fullchain-file /etc/grumpymail/certs/fullchain.pem \
        --reloadcmd     "/usr/local/bin/reload-services.sh" \
        --force || echo "Warning: Failed to generate certificates, using self-signed certs"
fi

# Update site config, make sure ssl is enabled
echo "server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $HOSTNAME;

    ssl_certificate /etc/grumpymail/certs/fullchain.pem;
    ssl_certificate_key /etc/grumpymail/certs/privkey.pem;

    # special config for EventSource to disable gzip
    location /api/events {
        proxy_http_version 1.1;
        gzip off;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header HOST \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:3000;
        proxy_redirect off;
    }

    # special config for uploads
    location /webmail/send {
        client_max_body_size 15M;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header HOST \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:3000;
        proxy_redirect off;
    }

    location / {
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header HOST \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:3000;
        proxy_redirect off;
    }
}" > "/etc/nginx/sites-available/$HOSTNAME"

#See issue https://github.com/nodemailer/grumpymail/issues/83
$SYSTEMCTL_PATH start nginx
$SYSTEMCTL_PATH reload nginx

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
