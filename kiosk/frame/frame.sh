#!/bin/bash

snap install ubuntu-frame
snap set ubuntu-frame config="
--cursor null
"

# Web
snap install chromium

# Config
# ~/.chromium-browser.init 
snap set chromium kiosk=yes incognito=yes noerrdialogs=yes disable-session-crashed-bubble=yes disable-pinch=yes url=http://localhost
snap set chromium daemon=true
snap connect chromium:wayland
snap connect chromium:wayland ubuntu-frame:wayland
snap restart chromium

# Images / Video via chromium
mkdir -p /media/content
snap set chromium daemon=true
snap connect chromium:removable-media
snap set chromium url=file:///media/content/{file}
snap restart chromium

#snap install wpe-webkit-mir-kiosk
#snap connect wpe-webkit-mir-kiosk:wayland ubuntu-frame:wayland


# Enable Frame
snap set ubuntu-frame daemon=true