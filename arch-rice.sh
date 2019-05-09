#!/usr/bin/env bash

### Script variables
SCRIPT_LOC="${0%/*}"

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
            USER_PASS=""
        fi
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

set_window_manager()
{
    #Install and configure windows manager
    if [ $WINDOW_MANAGER = "i3" ]
    then
        pacman -S xorg-server xorg-xinit i3-gaps i3blocks ttf-dejavu otf-font-awesome ttf-roboto dmenu --noconfirm
        #sudo -u $USER_NAME cp /etc/i3status.conf ~/.config/i3status/config
        
        sudo -u $USER_NAME bash -c "cat <<EOF > ~/.xinitrc
#!/usr/bin/env bash
exec i3
EOF
"
    fi
}

set_terminal()
{
    if [ $TERMINAL = "termite" ]
    then
        pacman -S termite --noconfirm
    fi
}

add_blackarch_repo()
{
    curl -o /tmp/strap.sh -O https://blackarch.org/strap.sh
    chmod +x /tmp/strap.sh
    /tmp/strap.sh 
}

configure_environment()
{
    sudo -u $USER_NAME bash -c "cp -Rf $SCRIPT_LOC/.config/ ~/.config" 
}

install_tools()
{
    BASE_TOOLS="vim tk htop strace"
    NETWORK_TOOLS="whois nmap tcpdump openvpn"
    DEV_TOOLS="firefox python python-pip apache"
    SECURITY_TOOLS="metasploit"
    METASPLOIT="metasploit postgresql"
    pacman -S $BASE_TOOLS $NETWORK_TOOLS $DEV_TOOLS $SECURITY_TOOLS $METASPLOIT --noconfirm
    
    #Setup Postgres and Metasploit
    systemctl start postgresql
    sudo -u postgres bash -c "initdb -D /var/lib/postgres/data"
    sudo -u postgres bash -c "createuser -s $USER_NAME"
    sudo -u $USER_NAME bash -c "createdb msf"
    sudo -u $USER_NAME bash -c "cat <<EOF > ~/.msf4/database.yml
production:
  adapter: postgresql
  database: msf
  username: $USER_NAME
  host: localhost
  port: 5432
  pool: 5
  timeout: 5
EOF
"
    sudo -u $USER_NAME bash -c "msfconsole --quiet -r - <<EOF
db_rebuild_cache
sleep 120
exit -y
EOF
"
}
###
## Main
###
check_root
update_pacman_system
configure_sudoers
create_user
set_shell
set_window_manager
set_terminal
add_blackarch_repo
configure_environment
install_tools