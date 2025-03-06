#!/bin/bash

# Formatting
NC='\033[0m'       # Text Reset
Green='\033[0;32m'        # Green

echo 'Enter new php version to install and sync current modules to'
read -p 'New Version: (eg: 8.4)' newversion

echo 'Enter current version to sync modules from: '
(cd /usr/bin/ && ls -la php[1-9]*.[0-9]*)
read -p 'Target Version: '  targetversion

echo -e "Download and install all php modules from ${Green}$targetversion${NC} to ${Green}$newversion${NC}?"
apt list --installed | grep php$targetversion
read -p "Continue? (Y/N): " confirm && [ $confirm == [yY] ] || exit 1

if confirm; then
sudo apt install $(apt list --installed | grep "php$targetversion-" | cut -d'/' -f1 | sed -e "s/$targetversion/$newversion/g") 
fi

###
# Patch php.inis
###

read -p 'Apply common patches to php.ini'\''s?' inipatch && [ $confirm == [yY] ] || exit 1

if inipatch; then
sed -i 's/post_max_size \= .M/post_max_size \= 32M/g' /etc/php/$newversion/fpm/php.ini
sed -i 's/upload_max_filesize \= .M/upload_max_filesize \= 32M/g' /etc/php/$newversion/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/$newversion/fpm/php.ini
sed -i 's/session.gc_maxlifetime = \b1440\b/session.gc_maxlifetime = 14400/g' /etc/php/$newversion/fpm/php.ini 
fi

sudo a2enconf php$newversion-fpm
sudo systemctl reload apache2
sudo systemctl status php$newversion
