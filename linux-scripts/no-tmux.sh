#!/bin/bash
# 
# no-tmux.sh
# When tmux can't be installed. Run necessary scripts.
# 
# Kaicheng Ye
# Jan. 2024

# Check if script has been run with superuser privileges
if [[ "$(id -u)" != "0" ]]
then
    printf "${error}ERROR: The script must be run with sudo privileges!${reset}\n"
    exit 1
fi

# crontabs
./check-cron.sh

# login banners
./login-banners.sh

# apt update and yum's equivalent
if [[ "$PKG_MAN" == "apt-get" ]]
then
    apt-get update -y &
    UPDATE_PID=$!
else
    yum clean expire-cache -y
    yum check-update -y &
    UPDATE_PID=$!
fi

# av
# wait for update to finish
wait $UPDATE_PID
if [[ "$PKG_MAN" == "apt-get" ]]
then
    apt-get install rkhunter -y --force-yes
else
    yum install epel-release -y
    yum install rkhunter -y
fi

rkhunter --check --sk
printf "${info}Scan complete, check /var/log/rkhunter.log for results${reset}\n"

# upgrade
./osupdater.sh
# backup again after update
./backup.sh

# splunk
cd ./logging
./install_and_setup_forwarder.sh
cd ../

exit 0

