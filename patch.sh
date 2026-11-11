#!/bin/bash
#https://stackoverflow.com/questions/5195607/checking-bash-exit-status-of-several-commands-efficiently/54190627#54190627
# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
#

workingdir="$(realpath $(dirname "$0"))"
. "${workingdir}/framework.sh"

# Load INI
read -p "Select env ini file: " inifile
if [ -f "${workingdir}/${inifile}" ]; then
    source <(grep = ${inifile})
else 
    echo_failure "unable to locate ${inifile}"
fi

#-----------------#
# Kiosk Builder 
#-----------------#

step "Elevate to sudo"
[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@" 
next

read -p "Set Hostname: " hostname
step "Hostname"
try hostnamectl set-hostname "$hostname"
try sed -i "/127.0.1.1/s/$/ ${hostname}${domain}/" /etc/hosts
next

step "Knobble Gnome"
try mkdir -p /etc/skel/.config
try echo "yes" > /etc/skel/.config/gnome-initial-setup-done
try chmod 754 /etc/skel/.config/gnome-initial-setup-done
try apt-get purge -y -qq gnome-initial-setup
next

step "Install safety"
try systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target ctrl-alt-del.target
try systemctl stop unattended-upgrades
try systemctl daemon-reload
next

step "Timezone"
do=true
try timedatectl list-timezones | grep -E "America|Europe"
while $do; do
    echo -n "Set Timezone: "
    read -r timezone
    try timedatectl set-timezone ${timezone}
    if [ $? -eq 0 ]; then
        do=false
    fi
done
next

step "Run patches"
try apt-get -qq update
try apt-get -y -qq upgrade
next

echo -n "Enable kiosk functionality? [y/N]: "
read -n 1 -r kiosk
echo
if [[ $kiosk =~ ^[Yy]$ ]]; then
    apt-get install -y ubuntu-desktop-minimal
fi 

#-----------------#
# Users
#-----------------#

step "Users"
# Select primary Admin User. 
admin=$( id -nu 1000 )
try mkdir -p /var/lib/AccountsService/users

# Add user 'deployment':
try $( id -u deployment &>/dev/null || adduser --disabled-password --gecos "" deployment &>/dev/null )
try cat > /var/lib/AccountsService/users/deployment << EOF
[User]  
Language=
SystemAccount=true  
EOF

# Add user 'display'
try $( id -u display &>/dev/null || adduser --disabled-password --gecos "" display &>/dev/null )
try cat > /var/lib/AccountsService/users/display << EOF
[User]
Session=gnome-kiosk-script-wayland
SystemAccount=true
EOF
# Depreciated due to :143 /etc/skel? 
# try mkdir -p /home/display/.config 
next

#-----------------#
# Groups
#-----------------#

# 2) If not exist create group highsudo 
step "Groups"
try $( [ $( getent group highsudo ) ] || groupadd highsudo )
try usermod -aG highsudo ${admin}
next

step "Sudoers"
try sed -i -n -e '/^%highsudo ALL=/!p' -e '$a%highsudo ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers
#try cat "${workingdir}/buildinit/etc/sudoers" >> /etc/sudoers
next

#-----------------#
# Prep
#-----------------#

step "Install-grub"
try sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/g' /etc/default/grub
try sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/g' /etc/default/grub
try sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash consoleblank=0"/g' /etc/default/grub
try update-grub
next

step "TimeSync"
try timedatectl set-ntp true
try systemctl restart chrony
next

#-----------------#
# SSH
#-----------------#

step "SSH"
try apt-get install -y -qq ssh 
try ufw allow 22022
# This is the old server config method
# try cp "./buildinit/etc/ssh/sshd_config.d/custom.conf" "/etc/ssh/sshd_config.d/custom.conf"
# try systemctl enable --now ssh
# This is the new socket method
try mkdir -p /etc/systemd/system/ssh.socket.d
try cp "${workingdir}/buildinit/etc/ssh/socket.conf" /etc/systemd/system/ssh.socket.d/override.conf
try systemctl daemon-reload
try systemctl restart ssh.socket

try mkdir -p /home/${admin}/.ssh /home/deployment/.ssh
try 
try echo "$adminkey" > /home/${admin}/.ssh/authorized_keys

try chown -R ${admin}:${admin} /home/${admin}/.ssh 
try chmod 700 /home/${admin}/.ssh 
try chmod 644 /home/${admin}/.ssh/authorized_keys

try  echo "$deploykey" > /home/deployment/.ssh/authorized_keys

try chown -R deployment:deployment /home/deployment/.ssh 
try chmod 700 /home/deployment/.ssh 
try chmod 644 /home/deployment/.ssh/authorized_keys
next

step "UFW"
try systemctl enable --now ufw
try echo "y" | ufw enable
next

#-----------------#
# Tweaks
#-----------------#

step "Tweaks"
try cat "${workingdir}/buildinit/~/.bashrc" >> /etc/bash.bashrc
try source ~/.bashrc
try cat "${workingdir}/buildinit/~/.vimrc" >> /etc/vim/vimrc
next 

step "motd"
try apt-get install -y -qq update-motd 
try cat "${workingdir}/buildinit/etc/update-motd.d/92-custom-message" >> /etc/update-motd.d/92-custom-message
try chmod 755 /etc/update-motd.d/92-custom-message
next

step "Prevent boot wait on network"
try mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
try cat > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf << EOF
[Service]  
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --any --timeout=1
EOF
next

#-----------------#
# LAMP
#-----------------#

step "Apache"
try apt-get install -y -qq apache2
try ufw allow in "Apache Full"
try sed -i "/#ServerRoot \"\/etc\/apache2\"/a SERVERNAME ${hostname}${domain}" /etc/apache2/apache2.conf
try a2enmod rewrite env ssl
try sed -i 's/.*DirectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/apache2/mods-available/dir.conf
try systemctl enable --now apache2
try usermod -aG www-data deployment
try mkdir -p /webfiles/websites
try chown -R ${admin}:www-data /webfiles/websites
try chmod 775 /webfiles/websites
try sed -i '\|<Directory /srv/>|i \
<Directory /webfiles\/websites/>\
    Options FollowSymLinks\
    Require all granted\
</Directory>' /etc/apache2/apache2.conf
try cp "${workingdir}/buildinit/etc/apache2/sites-available/001-custom.conf" /etc/apache2/sites-available/001-custom.conf
try chmod 644 /etc/apache2/sites-available/001-custom.conf
try sed -i "/ServerName/s/$/ ${hostname}${domain}/" /etc/apache2/sites-available/001-custom.conf
try a2dissite 000-default.conf
try systemctl restart apache2
sleep 1
next

step "PHP"
#try LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
try apt-get install -y -qq php php-cli php-bcmath php-curl php-fpm php-gd php-json php-mbstring php-mysql php-odbc php-readline php-xml php-zip #libapache2-mod-php 
try a2enmod proxy_fcgi setenvif
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
try sed -i "s/VER-fpm/${PHP_VERSION}-fpm/" /etc/apache2/sites-available/001-custom.conf
try a2ensite 001-custom.conf
try a2enconf php$PHP_VERSION-fpm
try cp "${workingdir}/php/deploy_new_php_version.sh" "/etc/php/deploy_new_php_version.sh"
try sed -i 's/post_max_size \= .M/post_max_size \= 32M/g' /etc/php/$PHP_VERSION/fpm/php.ini
try sed -i 's/upload_max_filesize \= .M/upload_max_filesize \= 32M/g' /etc/php/$PHP_VERSION/fpm/php.ini
try sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/$PHP_VERSION/fpm/php.ini
try sed -i 's/session.gc_maxlifetime = \b1440\b/session.gc_maxlifetime = 14400/g' /etc/php/$PHP_VERSION/fpm/php.ini 
try sed -i "/<\/VirtualHost>/i <FilesMatch \.php$>" /etc/apache2/sites-available/000-default.conf
try sed -i "/<\/VirtualHost>/i <\/FilesMatch>" /etc/apache2/sites-available/000-default.conf
try sed -i '/<\/FilesMatch>/i SetHandler "proxy:unix:/run/php/php'$PHP_VERSION'-fpm.sock|fcgi://localhost"' /etc/apache2/sites-available/000-default.conf
try systemctl daemon-reload
try systemctl restart apache2
try echo "php$PHP_VERSION Installed"
next

#step "SQL"
#try apt-get install -y -qq mysql-server
#try systemctl enable --now mysql
#next
#step "HTTPS"
#try apt-get install -y -qq certbot python3-certbot-apache
#try certbot --apache
#next


#-----------------#
# Repos
#-----------------#

step "Custom Repos"
try mkdir -p /opt/repos 
try ln -s /opt/repos /home/deployment/repos
try cp "${workingdir}/git/hooks/post-receive" "/opt/repos/post-receive"
try chown -R deployment:deployment /opt/repos /home/deployment
try chmod g+ws /opt/repos
try chmod ug+wx "/opt/repos/post-receive"
next

#-----------------#
# Kiosk Settings
#-----------------#

if [[ $kiosk =~ ^[Yy]$ ]]; then
    . "${workingdir}/kiosk/kiosk.sh"
fi

#-----------------#
# End
#-----------------#

step "Out"
try apt-get autoremove -y -qq
#try apt -o=Dpkg::Use-Pty=0 -y -qq autoremove
try echo "Device IP: " && hostname -I
if [[ $kiosk =~ ^[Yy]$ ]]; then 
    try systemctl disable --now unattended-upgrades
else 
    try systemctl start unattended-upgrades
fi
try systemctl daemon-reload
next 

read -p 'Reboot to apply? [Y]' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo 'Script ended'
else
    systemctl reboot -i
fi