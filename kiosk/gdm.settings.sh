#!/bin/bash
# Environment file, must be sudo
[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@" 

try mkdir -p /etc/dconf/profile
try tee /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

try mkdir -p /etc/dconf/db/local.d
try tee /etc/dconf/db/local.d/00-custom << 'EOF'
[org/gnome/settings-daemon/plugins/power]
sleep-interactive-ac-timeout=0
idle-brightness=0
idle-dim=false

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=false
ubuntu-lock-on-suspend=false

[org/gnome/desktop/lockdown]
disable-lock-screen=true

[org/gnome/desktop/login-screen]
disable-user-list=true

[org/gnome/desktop/interface]
cursor-theme='Transparent'

[com/ubuntu/update-notifier]
no-show-notifications=true
show-updates-status-icon=false

[org/gnome/desktop/wm/preferences]
num-workspaces=1

[org/gnome/mutter]
dynamic-workspaces=false

[org/gnome/settings-daemon/plugins/media-keys]
terminal=@as []
help=@as []
logout=@as []

[org/gnome/desktop/wm/keybindings]
switch-applications=@as []
switch-applications-backward=@as []
switch-windows=@as []
switch-windows-backward=@as []
panel-run-dialog=@as []
panel-main-menu=@as []
EOF

try mkdir -p /etc/dconf/db/local.d/locks
try tee /etc/dconf/db/local.d/locks/prevent-lock << 'EOF'
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/screensaver/ubuntu-lock-on-suspend
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/lockdown/disable-lock-screen
/org/gnome/desktop/lockdown
/com/ubuntu/update-notifier
/org/gnome/settings-daemon/plugins/power
/org/gnome/desktop/session
/org/gnome/desktop/screensaver
/org/gnome/desktop/login-screen
/org/gnome/desktop/wm/preferences
/org/gnome/mutter
EOF

try dconf update