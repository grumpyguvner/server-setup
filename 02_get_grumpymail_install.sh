#! /bin/bash

# This script downloads all the installation files.
BASEURL="https://raw.githubusercontent.com/grumpyguvner/server-setup/master/grumpymail/"

## declare an array
declare -a arr=(
"00_install_global_functions_variables.sh"
"01_install_commits.sh"
"02_install_prerequisites.sh"
"03_install_nginx.sh"
"04_install_ssl_certs.sh"
"05_install_check_running_services.sh"
"06_install_import_keys.sh"
"07_install_packages.sh"
"08_install_enable_services.sh"
"09_install_grumpymail.sh"
"10_install_haraka.sh"
"11_install_zone_mta.sh"
"12_install_webmail.sh"
"13_install_ufw_rules.sh"
"14_install_start_services.sh"
"15_install_deploy.sh"
"install.sh"
)

if [ -d "/root/grumpymail_install" ]; then
  rm -rf /root/grumpymail_install
fi

mkdir /root/grumpymail_install && cd /root/grumpymail_install

for i in "${arr[@]}"
do
  curl -sSL -o $i ${BASEURL}$i
done

chmod +x install.sh
./install.sh
