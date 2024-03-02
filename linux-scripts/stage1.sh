#!/bin/bash
# 
# stage1.sh
# 
# Stage 1 of 2?
# 
# Kaicheng Ye
# Feb. 2024

# Check if script has been run with superuser privileges
if [[ "$(id -u)" != "0" ]]
then
    printf "${error}ERROR: The script must be run with sudo privileges!${reset}\n"
    exit 1
fi

printf "Initiating stage 1\n"

STAGE1=1
export STAGE1

mkdir work
cd work

MACHINE="$1"

case $MACHINE in
    "dns-ntp")     ;;
    "ecomm")       ;;
    "splunk")      ;;
    "web")         ;;
    "webmail")     ;;
    "workstation") ;;
    "")            ;;
    *)
printf "${error}ERROR: Enter respective name according to machine's purpose:
    dns-ntp
    ecomm
    splunk
    web
    webmail
    workstation
    or no parameters for generic${reset}\n"; exit 1 ;;
esac


wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/pansophy.sh -O pansophy.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/backup.sh -O backup.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/check-cron.sh -O check-cron.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/firewall.sh -O firewall.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/restore-backup.sh -O restore-backup.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/linux-scripts/secure-os.sh -O secure-os.sh
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/palo-alto/prophylaxis.txt -O prophylaxis.txt
wget --no-cache https://raw.githubusercontent.com/CedarvilleCyber/CCDC/main/palo-alto/prophylaxis.sh -O prophylaxis.sh

chmod 700 pansophy.sh
chmod 700 backup.sh
chmod 700 check-cron.sh
chmod 700 firewall.sh
chmod 700 restore-backup.sh
chmod 700 secure-os.sh
chmod 700 propylaxis.sh

# check cron now!
./check-cron.sh

./pansophy.sh "$MACHINE" "stage1"

git clone https://github.com/CedarvilleCyber/CCDC.git --depth 1

printf "\n\nBasics secured. Now,   cd ./work/CCDC/linux-scripts
and run pansophy.sh like normal\n\n\n"

exit 0
