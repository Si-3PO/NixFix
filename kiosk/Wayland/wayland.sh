#!/bin/bash

# Set GDM3
# /etc/gdm3/custom.conf
step "GDM3 User"
try cp "${workingdir}/buildinit/etc/gdm3/custom.conf" /etc/gdm3/custom.conf
next

# Set user session
# /var/lib/AccountsService/users/{user}
step "Wayland User session"
try touch /var/lib/AccountsService/users/display
#try cp "${workingdir}/var/lib/AccountsService/users/display" /var/lib/AccountsService/users/display
try sed -i 's/X-GDM-SessionRegisters=.*/X-GDM-SessionRegisters=true/g' /usr/share/wayland-sessions/gnome-kiosk-script-wayland.desktop
next

# Configure user session
# ~/.local/bin/gnome-kiosk-script

step "Wayland User"
try mkdir -p /home/display/.local/bin/
try cp "${workingdir}/kiosk/Wayland/gnome-kiosk-script" /home/display/.local/bin/gnome-kiosk-script
try ln -s /home/display/.local/bin/gnome-kiosk-script gnome-kiosk-script
try chmod +x /home/display/.local/bin/gnome-kiosk-script
try chown -R display:display /home/display
next
