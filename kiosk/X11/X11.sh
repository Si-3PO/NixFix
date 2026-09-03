#!/bin/bash
step "X11"
try apt-get install -y -qq dbus-x11
try gsettings set org.gnome.desktop.session idle-delay 0
try mv /usr/share/xsessions/ubuntu.desktop /usr/share/xsessions/ubuntu.notdesktop
try mv /usr/share/xsessions/ubuntu-xorg.desktop /usr/share/xsessions/ubuntu-xorg.notdesktop
try mv /usr/share/wayland-sessions/ubuntu.desktop /usr/share/wayland-sessions/ubuntu.notdesktop
next

step "Kiosk_Packages"
try apt -o=Dpkg::Use-Pty=0 -qq update &>/dev/null
try apt-get install -y -qq xorg chromium openbox wmctrl feh mpv imagemagick unclutter
sleep 1
try $( DEBIAN_FRONTEND="noninteractive" DEBCONF_NONINTERACTIVE_SEEN="true" apt-get install -o=Dpkg::Use-Pty=0 -y lightdm &>/dev/null ) && echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager && dpkg-reconfigure -f noninteractive lightdm
try sed -i '/hidden-users/ s/$/ deployment/' /etc/lightdm/users.conf
try apt-get -y -qq install inotify-tools
next

step "Kiosk_config"
try cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=display
user-session=openbox
xserver-command=X -s 0 -dpms
EOF

try cat > /etc/X11/xorg.conf.d/xorg.conf << EOF
Section "ServerFlags"
Option "blank time" "0"
Option "standby time" "0"
Option "suspend time" "0"
Option "off time" "0"
EndSection
EOF

try mkdir -p /home/display/.config/openbox
try chown -R display:display /home/display/.config
next


step "Openbox_config"
try cp -R "./custom/~/.config/openbox" /home/display/.config/
try chown -R display:display /home/display/.config/openbox/
try chmod -R 775 /home/display/.config/openbox/

# Set default display mode = Dual Video
try cp /home/display/.config/openbox/daymode /home/display/.config/openbox/autostart

try openbox --reconfigure
next