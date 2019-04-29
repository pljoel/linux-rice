#!/usr/bin/env bash

####
### Arch rice
####

### Variables
USER_NAME="joel"
USER_PASS=""
USER_SHELL="fish"

WINDOW_MANAGER="i3"
#$(openssl passwd -1 $USER_PASS)
TERMINAL="termite"

check_root()
{
    SCRIPT_USER="$(whoami)"
    if ! [ "$SCRIPT_USER" == "root" ]
    then
        echo "The script needs to be run as root."
        return 1
    fi
}

update_pacman_system()
{
    pacman -Syyu --noconfirm
}

configure_sudoers()
{
    pacman -S sudo --noconfirm
    sed -i 's/^#\s*\(%sudo\s*ALL=(ALL)\s*ALL\)/\1/' /etc/sudoers
    groupadd -g 27 sudo
}

create_user()
{
    if [ -z "$USER_NAME" ]
    then
        echo "Username is unset"
        echo -n "Enter a username and press [ENTER]: "
        read USER_NAME
        useradd -m -G sudo $USER_NAME
        echo "Enter a password for $USER_NAME ..."
        passwd $USER_NAME
    else
        echo "Username = $USER_NAME "
        if [ -z "USER_PASS" ]
        then
            echo "User password is empty"
            useradd -m -G sudo $USER_NAME
            echo "Enter a password for $USER_NAME ..."
            passwd $USER_NAME
        else
            echo "User password is set"
            useradd -m -G sudo -p $(openssl passwd -1 $USER_PASS) $USER_NAME
            USER_PASS = ""
        fi
    fi
}

set_window_manager()
{
    #Install and configure windows manager
    if [ $WINDOW_MANAGER = "i3" ]
    then
        pacman -S xorg-xinit i3-wm ttf-font-awesome dmenu --noconfirm
        #sudo -u $USER_NAME cp /etc/i3status.conf ~/.config/i3status/config
        
        sudo -u $USER_NAME cat <<EOF > ~/.xinitrc
#!/usr/bin/env bash
exec i3-wm
EOF

    fi
}

set_shell()
{
    if [ $USER_SHELL = "fish" ]
    then
        pacman -S fish --noconfirm
        chsh -s /usr/bin/fish $USER_NAME
    fi
}

set_terminal()
{
    if [ $TERMINAL = "termite" ]
    then
        pacman -S termite --noconfirm
    fi
}

###
## Main
###
check_root
update_pacman_system
configure_sudoers
create_user
set_window_manager
set_shell
set_terminal