#!/bin/bash
# Get the repo prepared on the new instance

[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@"

read -p "Select env ini file: " inifile
if [ -f "./${inifile}" ]; then
    try source <(grep = ${inifile})
else 
    echo_failure "unable to locate ${inifile}"
    exit 1
fi

apt update -y
apt install -y smbclient cifs-utils
mkdir -p /root/setup /mnt/source
umount /mnt/source
mount -t cifs -o user=${smbuser},pass=${smbpass} ${smbshare} /mnt/source
rsync -avh /mnt/source/ /root/setup/ --delete --progress