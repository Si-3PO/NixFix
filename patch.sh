#!/bin/bash
###
# Builder file
###

# 1) If not exist create group highsudo 
if [ $(getent group highsudo || sudo groupadd highsudo) ]; then
    # 2) Patch current user into highsudo
    sudo usermod -aG highsudo $(whoami)
    echo "user added to highsudo group"
    section=2
else 
    # Error Condition: Failed to both find and create highsudo group
    echo "Error condition #1, aborting script"
    exit 1
fi

# 3) Update sudoers file with highsudo perms
if [$section -eq 2]; then
    sudo cat "./etc/sudoers" >> "/etc/sudoers"
    echo "Sudoers file patched"
    section=3
fi

# 4) Update SSH with custom config 
echo "This will deny SSH Passwords by default. Ensure an SSH Keypair is established and working."
if [$section -eq 3]; then
    sudo ufw allow 22022;

    sudo cp "./etc/ssh/sshd_config.d/custom.conf" "/etc/ssh/sshd_config.d/custom.conf"

    if [$(sudo sshd -t && test -f ~/.ssh/authorized_keys)]; then
        echo "Authorized Keys file found, restarting sshd service on command"
        while true; do
            read -t 5 -p "Restart sshd service?" answer
            case $answer in
                [Yy]* ) sudo systemctl reload sshd;;
                * ) echo "Not restarting sshd, will require manual restart to apply"
            esac
        done
    else
        echo "Error: sshd config fail, or authorized keys file is missing"
    fi

    section=4
fi

# 5) Make our bash better
if [$section -eq 4]; then
    cat "./~/.bashrc" >> $(echo ~/.bashrc)
    echo "Local bash config patched"
    section=5
fi

# 6) Make our vim actually readable 
if [$section -eq 5]; then 
    cat "./~/.vimrc" >> $(echo ~/.vimrc)
    echo "Local vim config patched"
    section=6
fi
source ~/.bashrc

# 7) Prettify Welcome screen 
if [$section -eq 6]; then 
    sudo cp "./etc/update-motd.d/92-custom-message" >> "/etc/update-motd.d/92-custom-message"
    sudo chmod 755 /etc/update-motd.d/92-custom-message
    echo "Motd patched"
    section=7
fi

echo "All complete"