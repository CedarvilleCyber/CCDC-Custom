#!/bin/bash

clear

echo
echo "---------------- 2023 CU CCDC Password Policy Guide ----------------"
echo

echo "This script gives the steps to implementing the password policy."
echo
echo "Configuration is different based on the distribution family used"
echo "Enter [Debian] if you are on DNS/NTP, Web, or Workstation"
echo "Enter [RHEL] if you are on Ecomm, Splunk, or Webmail"
read -p "Distribution family: " DIST_FAM

while [[  DIST_FAM != "Debian" && DIST_FAM != "RHEL" ]]
do
    echo "Enter 'Debian' or 'RHEL' exactly"
    read -p "Distribution family: " DIST_FAM
done

echo
echo "Follow these steps to enforce the password policy."
echo
case "$DIST_FAM" in
    "Debian")
        # Possibly need to check libpam-cracklib is installed (not sure)
        
        echo "# vi /etc/pam.d/common-password"
        # Prevent re-use of past 3 passwords
        echo "    Add 'remember=3' to line with:"
        echo "      'password   [success=1 default=ignore]  pam_unix.so'"
        echo
        # Requires at least one of each lower, upper, digit, and symbol 
        echo "    Add this line above the previous line: "
        echo "      'password   required   pam_pwquality.so minclass=4 minlen=15'"
        echo
        # Set password expiration
        echo "# vi /etc/login.defs"
        echo "    Find and set:"
        echo "      'PASS_MAX_DAYS 180'"
        echo "      'PASS_MIN_DAYS 0'"
        echo "      'PASS_WARN_AGE 7'"
        echo
        echo "    And a little further down:"
        echo "      'LOGIN_TIMEOUT 600'"
        ;;
        
    "RHEL")
        echo "# vi /etc/pam.d/system-auth"
        # Prevent re-use of past 3 passwords
        echo "    Add 'remember=3' to line with:"
        echo "      'password   sufficient  pam_unix.so'"
        echo
        # Requires at least one of each lower, upper, digit, and symbol 
        echo "    Add 'minclass=4 minlen=15' to line with:"
        echo "      'password   requisite   pam_pwquality.so'"
        echo
        # Set password expiration
        echo "# vi /etc/login.defs"
        echo "    Find and set:"
        echo "      'PASS_MAX_DAYS 180'"
        echo "      'PASS_MIN_DAYS 0'"
        echo "      'PASS_WARN_AGE 7'"
        echo
        echo "    And add the line:"
        echo "      'LOGIN_TIMEOUT 600'"
        ;;
esac

exit 0