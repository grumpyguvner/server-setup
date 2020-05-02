#! /bin/bash

OURNAME=15_install_deploy.sh

# No $AUT_SAFETY variable present, so we have not sourced install_variables.sh yet
# check if $AUT_SAFETY is unset (as opposed to empty "" string)
if [ -z ${AUT_SAFETY+x} ]
  then
    echo "this script ${RED}called directly${NC}, and not from the main ./install.sh script"
    echo "initializing common variables ('install_variables.sh')"
    source "$INSTALLDIR/install_variables.sh"
fi

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

cd "$INSTALLDIR"

echo "DEPLOY SETUP

1. Add your ssh key to /home/deploy/.ssh/authorized_keys

2. Clone application code
\$ git clone deploy@$HOSTNAME:/var/opt/grumpymail.git
\$ git clone deploy@$HOSTNAME:/var/opt/zone-mta.git
\$ git clone deploy@$HOSTNAME:/var/opt/webmail.git
\$ git clone deploy@$HOSTNAME:/var/opt/haraka-plugin-grumpymail.git
\$ git clone deploy@$HOSTNAME:/var/opt/zonemta-grumpymail.git

3. After making a change in local copy deploy to server
\$ git push origin master
(you might need to use -f when pushing first time)

NAMESERVER SETUP
================

MX
--
Add this MX record to the $MAILDOMAIN DNS zone:

$MAILDOMAIN. IN MX 5 $HOSTNAME.

SPF
---
Add this TXT record to the $MAILDOMAIN DNS zone:

$MAILDOMAIN. IN TXT \"v=spf1 a:$HOSTNAME a:$MAILDOMAIN ip4:$PUBLIC_IP ~all\"

Or:
$MAILDOMAIN. IN TXT \"v=spf1 a:$HOSTNAME ip4:$PUBLIC_IP ~all\"
$MAILDOMAIN. IN TXT \"v=spf1 ip4:$PUBLIC_IP ~all\"

DKIM
----
Add this TXT record to the $MAILDOMAIN DNS zone:

$DKIM_SELECTOR._domainkey.$MAILDOMAIN. IN TXT \"$DKIM_DNS\"

The DKIM .json text we added to grumpymail server:
    curl -i -XPOST http://localhost:8080/dkim \\
    -H 'Content-type: application/json' \\
    -d '$DKIM_JSON'


Please refer to the manual how to change/delete/update DKIM keys
via the REST api (with curl on localhost) for the newest version.

List DKIM keys:
    curl -i http://localhost:8080/dkim
Delete DKIM:
    curl -i -XDELETE http://localhost:8080/dkim/59ef21aef255ed1d9d790e81

Move DKIM keys to another machine:

Save the above curl command and dns entry.
Also copy the following two files too:
/opt/zone-mta/keys/[MAILDOMAIN]-dkim.cert
/opt/zone-mta/keys/[MAILDOMAIN]-dkim.pem

pem: private key (guard it well)
cert: public key


PTR
---
Make sure that your public IP has a PTR record set to $HOSTNAME.
If your hosting provider does not allow you to set PTR records but has
assigned their own hostname, then edit /etc/zone-mta/pools.toml and replace
the hostname $HOSTNAME with the actual hostname of this server.

(this text is also stored to $INSTALLDIR/$MAILDOMAIN-nameserver.txt)" > "$INSTALLDIR/$MAILDOMAIN-nameserver.txt"

printf "Waiting for the server to start up.."

until $(curl --output /dev/null --silent --fail http://localhost:8080/users); do
    printf '.'
    sleep 2
done
echo "."

# Ensure DKIM key
echo "Registering DKIM key for $MAILDOMAIN"
echo $DKIM_JSON

curl -i -XPOST http://localhost:8080/dkim \
-H 'Content-type: application/json' \
-d "$DKIM_JSON"

echo ""
cat "$INSTALLDIR/$MAILDOMAIN-nameserver.txt"
echo ""
echo "All done, open https://$HOSTNAME/ in your browser"
