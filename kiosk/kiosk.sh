#!/bin/bash

#-----------------#
# Workday Schedule
#-----------------#

step "Schedule"
try timedatectl set-timezone UTC
#try $( ( crontab -l 2>/dev/null || true; echo '0 18 * * 0-4 /usr/sbin/rtcwake -m off -l -t $(date +\%s -d "tomorrow 07:00")') | crontab - )
#try $( ( crontab -l 2>/dev/null || true; echo '0 18 * * 5 /usr/sbin/rtcwake -m off -l -t $(date +\%s -d "+2days 07:00")') | crontab - )
#try $( ( crontab -l 2>/dev/null || true; echo '30 17 * * 1-4 bash /home/display/.config/openbox/nightmode.sh') | crontab - )
#try $( ( crontab -l 2>/dev/null || true; echo '0 7 * * 1-5 bash /home/display/.config/openbox/daymode.sh') | crontab - )
next

#-----------------#
# Init Kiosk
#-----------------#

step "Desktop"
try apt-get install -y -qq ubuntu-desktop-minimal
next

step "Kiosk Core"
try apt-get install -y -qq gnome-kiosk-script-session
next

step "Kiosk_Packages"
sleep 1
try apt-get install -y -qq chromium feh mpv imagemagick 
sleep 1
try apt-get install -y -qq inotify-tools
next

step "Environmental vars"
try source "${workingdir}/kiosk/gdm.settings.sh"
next

step "Wayland"
try source "${workingdir}/kiosk/Wayland/wayland.sh"
next

step "Unclutter"
#try apt-get install -y -qq unclutter
#try echo 'UNCLUTTER_ARGS="-idle 0.1 -jitter 10"' >> /etc/default/unclutter
try cp -r "${workingdir}/themes/Transparent" /usr/share/icons/
try apt-get install -y -qq gnome-tweaks
try ln -sf /usr/share/icons/Transparent /usr/share/icons/default
next

#-----------------#
# Set Media
#-----------------#

step "Media"
rsync -ah "${workingdir}/media/" /usr/share/backgrounds
next
