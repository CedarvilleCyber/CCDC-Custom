#!/bin/bash
# script to setup login banners for any linux machine

echo "Running login banners script"
#check if user is root
if [ "$(id -u)" != "0" ]; then
	printf "You must be root!\n"
	exit 1
fi
BANNER="Warning: Only authorized users are permitted to login. All network activity is being monitored and logged, and may be used to investigate and prosecute any instance of unauthorized access."
echo $BANNER | tee -a /etc/issue /etc/issue.net > /dev/null
echo $BANNER | tee /etc/ssh/sshd-banner > /dev/null
echo "Banner /etc/ssh/sshd-banner" | tee -a /etc/ssh/sshd_config > /dev/null

# check if redhat or debian and run one or the other
# TODO might be a better idea for master script to ask user which one it is 
. /etc/os-release

if [ "$ID" == "centos" ] || [ "$ID" == "fedora" ]
then
    /etc/init.d/sshd restart
else
    /etc/init.d/ssh restart
fi