#!/bin/bash
# 
# secure-os.sh
# 
# Basis OS security that can be automated
# 
# Kaicheng Ye
# Dec. 2023

if [[ "$(id -u)" != "0" ]]
then
    printf "${error}ERROR: The script must be run with sudo privileges!${reset}\n"
    exit 1
fi

printf "${info}Starting secure-os script${reset}\n"


# environment variables
. /etc/os-release

# Package Manager
if [[ "$ID" == "fedora" || "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "ol" ]]
then
    export PKG_MAN=yum
elif [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID" == "linuxmint" ]]
then
    export PKG_MAN=apt-get

    # disable apt user input
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
else
    export PKG_MAN=apt-get

    # disable apt user input
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    printf "${error}ERROR: Unsupported OS, assuming apt-get${reset}\n"
fi

# create ./data-files if it doesn't already exist
if [[ ! -d ./data-files ]]
then
    mkdir data-files
fi

if [[ "$1" != "background" ]]
then
    # change file permissions
    # executable only for .sh extensions.
    # user only permissions except for on directories.
    find /home -type f > ./data-files/files.txt
    find /home -type d -exec chmod 755 {} +
    find /root -type f >> ./data-files/files.txt
    find /root -type d -exec chmod 755 {} +
    chmod 644 /etc/passwd
    chmod 640 /etc/shadow
    chmod 440 /etc/sudoers

    # reads through each line of a file, ignoring whitespace
    while IFS="" read -r f || [[ -n "$f" ]]
    do
        read -r line < $f
        if [[ "$line" == "#!/bin/bash" ]]
        then
            chmod 700 $f
        elif [[ "$line" == "#!/bin/sh" ]]
        then
            chmod 700 $f
        else
            chmod 600 $f
        fi

    done < ./data-files/files.txt


    # remove uneccesary applications
    $PKG_MAN remove nc -y
    $PKG_MAN remove netcat -y
    $PKG_MAN remove ncat -y


    # remove uneccesary services
    which systemctl >/dev/null
    if [[ $? -eq 0 ]]
    then
        # cups is a printing service
        # speech-dispatcher is some tts thing
        systemctl disable cups
        systemctl stop cups
        systemctl disable speech-dispatcher
        systemctl stop speech-dispatcher
    else
        service cups stop
        service speech-dispatcher stop
    fi

fi

# brute remove any service that contains blue or blu3...
# list of possible blues
which systemctl >/dev/null
if [[ $? -eq 0 ]]
then
    rm -rf ./data-files/blues.txt
    touch ./data-files/blues.txt
    BLUES="blue blu3 b1ue b1u3"

    # hunt for those services
    for blue in $BLUES
    do
        systemctl --type=service | tail -n +2 | head -n -7 | awk '{print $1}' | grep -i $blue >> ./data-files/blues.txt
    done

    # disable and stop
    # as well as try to move the service
    while IFS="" read -r line || [ -n "$line" ]
    do
        systemctl disable $line
        systemctl stop $line
        mv /etc/systemd/system/$line /etc/systemd/system/bad-$line
    done < ./data-files/blues.txt
fi



# move pre authorized keys
printf "${info}Looking for authorized_keys and moving them${reset}\n"
printf "${info}one directory up from where they were found${reset}\n"
find / -iname "authorized_keys" > ./data-files/a_keys-locations.txt 2>/dev/null

# reads through each line of a file, ignoring whitespace
while IFS="" read -r f || [[ -n "$f" ]]
do
    if [[ "$(basename $(dirname "$f"))" == ".ssh" ]]
    then
        printf "${info}$f${reset}\n"
        mv $f `dirname $f`/../
    fi
done < ./data-files/a_keys-locations.txt


# comment out anything in sudoers.d
printf "${info}Checking /etc/sudoers.d/ directory${reset}\n"
for file in /etc/sudoers.d/*
do
    sed -ie '/^[^#].*/ s/^/#/' $file
    rm -rf "$file"e
done


# counter to keep track of if we need to restart web server or not
counter=0
# stop php web shells
# First find all php.ini file locations
find / -iname "php.ini" > ./data-files/php-locations.txt 2>/dev/null

# reads through each line of a file, ignoring whitespace
while IFS="" read -r f || [[ -n "$f" ]]
do
    printf "${info}$f${reset}\n"

    # create backups before writing over the file
    name=`echo $f | sed 's/\//_/g'`
    cp $f /usr/bak/$name

    # make sure disable_functions is not commented out
    sed -i -e 's/;disable_functions\(.*\)/disable_functions\1/' $f

    # now use sed to edit the disable_functions line
    # Checks for different "states" of the "disable_functions" line

    CHECK=$(cat $f | grep "disable_functions = exec, shell_exec, system, passthru, popen, proc_open, pcntl_exec, pcntl_fork, curl_exec, curl_exec_multi, phpinfo, mail, mb_send_mail, dl,")

    if [[ -z "$CHECK" ]]
    then
        sed -i -e '/^disable_functions.*=.*$/ s/disable_functions.*=\(.*\)/disable_functions = exec, shell_exec, system, passthru, popen, proc_open, pcntl_exec, pcntl_fork, curl_exec, curl_exec_multi, phpinfo, mail, mb_send_mail, dl,\1/' $f
        ((counter++))
    fi

done < ./data-files/php-locations.txt

TEMP=""
TEMP+=`sed -ie '/^[^#].*rootme/ s/^/#/w /dev/stdout' /etc/httpd/conf/httpd.conf`
TEMP+=`sed -ie '/^[^#].*rootme/ s/^/#/w /dev/stdout' /etc/apache2/apache2.conf`
TEMP+=`find /etc/httpd/conf.modules.d/ -type f -exec sed -ie '/^[^#].*rootme/ s/^/#/w /dev/stdout' {} +`
a2dismod mod_rootme
a2dismod rootme
TEMP+=`apache2ctl -M | grep rootme`
if [[ "$TEMP" != "" ]]
then
    ((counter++))
fi

# Restart apache2/httpd or nginx if we changed php
# Just try everything. No need to test one at a time
if [[ $counter -ne 0 ]]
then
    printf "${info}Restarting Web Server${reset}\n"
    which systemctl >/dev/null
    if [[ $? -eq 0 ]]
    then
        systemctl restart apache2
        systemctl restart httpd
        systemctl restart nginx
    else
        service apache2 restart
        service httpd restart
        service nginx restart
    fi
fi

# suid and sgid
while IFS="" read -r line || [ -n "$line" ]
do
    line=`echo "$line" | rev | cut -c2- | rev`
    find /usr/bin -user root -perm /4000 -name "$line" -exec ls -al {} +
    find /usr/bin -user root -perm /4000 -name "$line" -exec chmod -s {} +
    find /usr/sbin -user root -perm /4000 -name "$line" -exec ls -al {} +
    find /usr/sbin -user root -perm /4000 -name "$line" -exec chmod -s {} +
    
    find /usr/bin -group root -perm /2000 -name "$line" -exec ls -al {} +
    find /usr/bin -group root -perm /2000 -name "$line" -exec chmod g-s {} +
    find /usr/sbin -group root -perm /2000 -name "$line" -exec ls -al {} +
    find /usr/sbin -group root -perm /2000 -name "$line" -exec chmod g-s {} +
done < ./bad-suid.txt


# Check for LD_ Environment Variables
printenv > ./data-files/env.txt
# unset ${!LD_@}      useless since this script is it's own shell, but could be used manually
FOUND=""
find /home -maxdepth 2 -not -iname "*_history" -type f > ./data-files/env
find /root -maxdepth 1 -not -iname "*_history" -type f >> ./data-files/env
find /etc/profile.d -type f >> ./data-files/env

# loop through each found thing and run above sed command
while IFS="" read -r f || [[ -n "$f" ]]
do
    FOUND+=`sed -ie '/^export LD_/ s/^/#/w /dev/stdout' "$f"`
    FOUND+=`sed -ie '/^export http_proxy/ s/^/#/w /dev/stdout' "$f"`
    FOUND+=`sed -ie '/^export https_proxy/ s/^/#/w /dev/stdout' "$f"`
    rm -rf "$f"e
done < ./data-files/env

FOUND+=`sed -ie '/^export LD_/ s/^/#/w /dev/stdout' /etc/profile`
FOUND+=`sed -ie '/^export http_proxy/ s/^/#/w /dev/stdout' /etc/profile`
FOUND+=`sed -ie '/^export https_proxy/ s/^/#/w /dev/stdout' /etc/profile`
rm -rf /etc/profilee

FOUND+=`sed -ie '/^export LD_/ s/^/#/w /dev/stdout' /etc/environment`
FOUND+=`sed -ie '/^export http_proxy/ s/^/#/w /dev/stdout' /etc/environment`
FOUND+=`sed -ie '/^export https_proxy/ s/^/#/w /dev/stdout' /etc/environment`
rm -rf /etc/environmente

# remove temp files
rm -rf ./data-files/env


# ld.so.preload check
if [[ -f /etc/ld.so.preload ]]
then
    FOUND+="/etc/ld.so.preload"
    mv /etc/ld.so.preload /etc/ld.so.preload_EVIL
fi

# rc.local check
if [[ -f /etc/rc.local ]]
then
    RC="/etc/rc.local"
    mv "/etc/rc.local" "/etc/rc.local_EVIL"
    mv "/etc/rc.d/rc.local" "/etc/rc.d/rc.local_EVIL"
fi

if [[ "$FOUND" != "" ]]
then
    printf "\n\n$FOUND\n\n"
    printf "\n\n${warn}WARNING: Found things preset. Please close out of all shells and logout.\n"
    printf "Then, come back and rerun pansophy like normal.${reset}\n\n"
fi

if [[ "$RC" == "/etc/rc.local" ]]
then
    printf "${warn}Discovered rc.local, renaming to /etc/rc.local_EVIL. Check file and restart if needed.${reset}\n"
    printf "Then, come back and rerun pansophy like normal.${reset}\n\n"
fi

if [[ "$1" != "background" ]]
then
    if [[ "$FOUND" != "" || "$RC" != "" ]]
    then
        exit 0
        #printf "${warn}Ignore above if run with pansophy.sh. Restart required later anyway.${reset}\n"
    fi
fi

printf "${info}secure-os finish\n\n${reset}"

exit 0
