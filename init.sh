#!/bin/bash
# Get a local copy of the repo prepared on the new instance. This file should be run before patch.sh in instances when not pulling from a cloud source (eg. Github)

[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@"

read -p "Select env ini file: " inifile
if [ -f "./${inifile}" ]; then
    source <(grep = ${inifile})
else 
    echo_failure "unable to locate ${inifile}"
    exit 1
fi

apt update -y
apt install -y smbclient cifs-utils
mkdir -p /root/setup /mnt/source
umount -l /mnt/source
mount -t cifs -o user=${smbuser},pass=${smbpass} ${smbshare} /mnt/source
rsync -avh /mnt/source/ /root/setup/ --delete --progress