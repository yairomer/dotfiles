#!/bin/bash
set -e
# set -x  # Debug: be verbose
# PS4='$LINENO: '  # Add lines number to debug output

## Main CLI function
## =================
app_name=dotcli

main_cli() {
    ## Parse args
    ## ==========
    usage() {
        echo "A CLI tool for running common setup commands"
        echo ""
        echo "usage: $app_name  <command>"
        echo "   or: $app_name -h         to print this help message."
        echo ""
        echo "Commands"
        for subcommand in "${subcommands[@]}"; do
            if [[ $subcommand != _* ]]; then
                echo "    $(printf "%-40s" "$subcommand")${descriptions[$subcommand]}"
            fi
        done
        echo "Use $app_name <command> -h for specific help on each command."
    }
    if [[ "$#" -eq 1 ]] && [[ "$1" ==  "-h" ]]; then
        usage
        exit 0
    fi

    while getopts ":h" opt; do
        case $opt in
            h )
                usage
                exit 0
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a command" 1>&2
        usage
        exit 1
    fi

    subcommand=$1; shift

    if ! is_valid_subcommand $subcommand; then
        echo "Error: unknown command $subcommand" 1>&2
        usage
        exit 1
    fi

    run_${subcommand} $@
}

## Auxiliaries
## ===========
# dotfiles_folder="$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )"
dotfiles_folder="$(dirname "$(readlink -f "$0")")"

is_valid_subcommand() {
    # Usage: is_valid_state state_name
    local subcommand=$1
    local in=1
    for curr_subcommand in "${subcommands[@]}"; do
        if [[ $curr_subcommand == $subcommand ]]; then
            in=0
            break
        fi
    done
    return $in
}

add_line() {
    # Usage: add_line filename "string" "title"

    local filename=$1
    local string=$2
    local title=$3
    title="dotcli up script: $title"

    if [ -z "$(grep -Fx "## $title" "$filename")" ]; then
        printf "\n## $title\n$string\n## $title - end\n"  | sudo tee "$1" >  /dev/null
    else
        if [ -z "$(grep -Fx "$string" "$filename")" ]; then
            sudo sed -i "/## $title - end/i$string" $filename
        fi
    fi
}

change_line() {
    # Usage: change_line filename "line to replace regex" "string"

    local filename=$1
    local line_regex=$2
    local string=$3

    if [ ! -z "$(sudo grep "^$string\$" "$filename")" ]; then
        :
    else
        if [ -z "$(sudo grep "$line_regex" "$filename")" ]; then
            echo "Error: could not find line to change \"$line_regex\" in \"$filename\"" 1>&2
            exit 1
        fi
        sudo sed -i "s/$line_regex/$string/g" $filename
    fi
}

## Subcommands
## ===========
declare -a subcommands;
declare -a descriptions_tmp;

## create_user_cli
## ---------------
subcommands+=( "create_user" )
descriptions_tmp+=( "Create a new user" )

run_create_user() {
    username=""
    user_uid=""
    user_gid=""
    hashed_password=""

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "    username                The user's name to creat."
        echo ""
        echo "Options:"
        echo "    -u user_uid             The uid to use if a new user is created"
        echo "    -g user_gid             The gid to use if a new user is created"
        echo "    -p hashed_password      A hashed password to use for a new user"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a user name" 1>&2
        usage
        exit 1
    fi

    username=$1; shift

    while getopts "u:g:p:" opt; do
        case $opt in
            u)
                user_uid=$OPTARG
                ;;
            g)
                user_gid=$OPTARG
                ;;
            p)
                hashed_password=$OPTARG
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if ! id -u "$username" >/dev/null 2>&1; then
        echo "-> Creating new user: \"$username\""
        if [ -z $hashed_password ]; then
            password_arg=""
        else
            password_arg="-p $hashed_password"
        fi
        if [[ -z "$user_uid" ]]; then
            uid_arg=""
        else
            uid_arg="-u $user_uid"
        fi
        if [[ -z "$user_gid" ]]; then
            gid_arg=""
        else
            sudo groupadd -g $user_gid $username
            gid_arg="-g $username"
        fi
        sudo useradd --system --create-home --shell /bin/bash -G sudo $password_arg $uid_arg $gid_arg $username
    fi
}

## copy_ssh_folder
## ---------------
subcommands+=( "copy_ssh_folder" )
descriptions_tmp+=( "Copy the .ssh folder user to user, if it dose not exist." )

run_copy_ssh_folder() {
    source_username="$USER"
    target_username=""

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand target_username [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "    target_username                The user to copy the .ssh folder to."
        echo ""
        echo "Options:"
        echo "    -u source_username             The the user from which to copy the .ssh folder. Default $source_username"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a target user name" 1>&2
        usage
        exit 1
    fi

    target_username=$1; shift

    while getopts ":u" opt; do
        case $opt in
            u)
                source_username=$OPTARG
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [[ $target_username == "root" ]]; then
        target_home_folder="/root"
    else
        target_home_folder="/home/$target_username"
    fi

    if [[ $source_username == "root" ]]; then
        source_home_folder="/root"
    else
        source_home_folder="/home/$source_username"
    fi

    if [ -d $source_home_folder/.ssh ] && [ ! -d $target_home_folder/.ssh ]; then
        echo "-> Copying .ssh folder from $source_username to $target_username"
        sudo cp -r $source_home_folder/.ssh $target_home_folder
        sudo chown -R $target_username:$target_username $target_home_folder/.ssh
    fi
}

## set_passwordless_sudo
## ---------------------
subcommands+=( "set_passwordless_sudo" )
descriptions_tmp+=( "Remove the need to enter a password when running sudo." )

run_set_passwordless_sudo() {
    username=$USER

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "Options:"
        echo "    -u username                    The user for which to apply the change. Default: $username"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "u:" opt; do
        case $opt in
            u)
                username=$OPTARG
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Setting passwordless sudo"
    if [[ -z "$username" ]]; then
        username=$USER
    fi
    add_line /etc/sudoers "$username ALL=(ALL:ALL) NOPASSWD: ALL" "Passwordless sudo"
}

## setup_ssh_server
## ----------------
subcommands+=( "setup_ssh_server" )
descriptions_tmp+=( "Setup a SSH server." )

run_setup_ssh_server() {

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "error: unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Installinf Open SSH server"
    sudo apt-get install -y openssh-server
}

## enable_ssh_password_login
## -------------------------
subcommands+=( "enable_ssh_password_login" )
descriptions_tmp+=( "Enable SSH login using username and password (without an SSH key file)." )

run_enable_ssh_password_login() {

    run_restart_ssh_daemon=false

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "Options:"
        echo "    -d                      Don't restart the SSH server"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "d" opt; do
        case $opt in
            d)
                run_restart_ssh_daemon=true
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "error: unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Enable SSH password login"
    change_line /etc/ssh/sshd_config "^#\?PasswordAuthentication .*$" "PasswordAuthentication yes"
    if [ "$run_restart_ssh_daemon" = true ]; then
        restart_ssh_daemon
    fi
}

## disable_ssh_root_login
## ----------------------
subcommands+=( "disable_ssh_root_login" )
descriptions_tmp+=( "Disable the option to connect as root through SSH." )

run_disable_ssh_root_login() {

    run_restart_ssh_daemon=false

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "Options:"
        echo "    -d                      Don't restart the SSH server"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "d" opt; do
        case $opt in
            d)
                run_restart_ssh_daemon=true
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "error: unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Disabling root SSH login"
    change_line /etc/ssh/sshd_config "^#\?PermitRootLogin .*\$" "PermitRootLogin no"
    if [ "$run_restart_ssh_daemon" = true ]; then
        restart_ssh_daemon
    fi
}

restart_ssh_daemon() {
    echo "-> Restarting SSH daemon"
    sudo service sshd restart
}

## setup_basic_firewall
## --------------------
subcommands+=( "setup_basic_firewall" )
descriptions_tmp+=( "Enable basic firewall." )

run_setup_basic_firewall() {

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "error: unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Setting up firewall"
    sudo ufw allow OpenSSH
    sudo ufw --force enable
}

## create_swapfile
## ---------------
subcommands+=( "create_swapfile" )
descriptions_tmp+=( "Create a swap file." )

run_create_swapfile() {
    swapfile_location=/swapfile
    swapfile_size=4G
    swapfile_swappiness=10
    swapfile_vfs_cache_pressure=50

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo ""
        echo "Options:"
        echo "    -l location             The location of the swap file. Default: $swapfile_location"
        echo "    -s size                 The size of the swap file. Default: $swapfile_size"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts ":l:s" opt; do
        case $opt in
            l)
                swapfile_location=$OPTARG
                ;;
            s)
                swapfile_size=$OPTARG
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "error: unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [ ! -f $swapfile_location ]; then
        echo "->Creating swap file"
        sudo fallocate -l $swapfile_size $swapfile_location
        sudo chmod 0600 $swapfile_location
        sudo mkswap $swapfile_location
        sudo swapon $swapfile_location
        add_line /etc/fstab "$swapfile_location   none    swap    sw    0   0" "Swap file"
        add_line /etc/sysctl.conf "vm.swappiness = $swapfile_swappiness" "Swap file"
        add_line /etc/sysctl.conf "vm.vfs_cache_pressure = $swapfile_vfs_cache_pressure" "Swap file"
        # change_line /etc/sysctl.conf "^vm.swappiness[\s]?=" "vm.swappiness = $swapfile_swappiness"
        # change_line /etc/sysctl.conf "^vm.vfs_cache_pressure[\s]?=" "vm.vfs_cache_pressure = $swapfile_vfs_cache_pressure"

        sudo sysctl -p
    fi
}

## update_apt
## ----------
subcommands+=( "update_apt" )
descriptions_tmp+=("Run apt-get update & apt-get upgrade." )

run_update_apt() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username [<options>]"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Update aptitude"
    sudo apt-get update -y || true
    sudo apt-get upgrade -y
}

## install_basic_tools
## -------------------
subcommands+=( "install_basic_tools" )
descriptions_tmp+=( "Install common pat packages" )

run_install_basic_tools() {

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install basic packages"
    ## Basic
    sudo apt-get install -y \
        software-properties-common \
        build-essential \
        cmake \
        python3 \
        python3-dev \
        python3-pip \
        python \
        python-dev \
        python-pip
    ## Utilities
    sudo apt-get install -y -qq \
        sshfs \
        wget \
        curl \
        rsync \
        ssh \
        vim \
        git \
        tig \
        tmux \
        unzip \
        htop \
        tree \
        silversearcher-ag \
        ctags \
        cscope \
        jq
    ## General development dependencies
    sudo apt-get install -y -qq \
        libblas-dev \
        liblapack-dev \
        gfortran
    sudo apt-get clean
}

## copy_to_workspace
## -----------------
subcommands+=( "copy_to_workspace" )
descriptions_tmp+=( "Copy the current dotfiles folder to ~/workspace/" )

run_copy_to_workspace() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    target_folder="$HOME/workspace/projects/dotfiles"
    if [ ! "$dotfiles_folder" == "$target_folder" ] &&  [ ! -d "$target_folder" ]; then
        echo "-> Moving the dotfiles folder to the workspace folder"
        mkdir -p $(dirname $target_folder)
        cp -r $dotfiles_folder $target_folder
    fi
}

## switch_to_ssh
## -------------
subcommands+=( "switch_to_ssh" )
descriptions_tmp+=( "Switch dotfiles repository's upstream to be SSH based." )

run_switch_to_ssh() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    pushd $dotfiles_folder
    git remote set-url origin git@github.com:yairomer/dotfiles.git
    popd
}

## install_bash_power_tools
## ------------------------
subcommands+=( "install_bash_power_tools" )
descriptions_tmp+=( "Install Vim + NeoVim + TMUX + Zsh." )

run_install_bash_power_tools() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install VIM + NeoVIM + TMUX + Zsh"
    # sudo add-apt-repository -y ppa:pkg-vim/vim-daily
    # sudo apt-get update || true
    sudo apt-get install -y -qq \
        vim \
        neovim \
        tmux \
        zsh
}

## install_omz
## -----------
subcommands+=( "install_omz" )
descriptions_tmp+=( "Install Oh-My-Zsh and plugins." )

run_install_omz() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    ## Install Oh my Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "-> Installing Oh My Zsh"
        git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
    fi

    ## Oh-my-zsh plugins
    pushd $HOME/.oh-my-zsh/custom/plugins
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting
    fi
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions
    fi
    popd
}

## link_dotfiles
## -------------
subcommands+=( "link_dotfiles" )
descriptions_tmp+=( "Create links in home folder to the dotfiles in the repository." )

run_link_dotfiles() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [ ! -d "$HOME/.dotfiles_backup" ]; then
        echo "-> backing up dotfiles"
        mkdir $HOME/.dotfiles_backup
        mkdir $HOME/.dotfiles_backup/.config
        mkdir $HOME/.dotfiles_backup/.vim
        mkdir -p $HOME/.dotfiles_backup/.jupyter/nbconfig/
        for i in .bashrc .tmux.conf .zshrc .vimrc .pylintrc .gitconfig .mpv .config/nvim .vim/init.vim .jupyter/nbconfig/notebook.json .dotfiles_bin; do
            if [[ (-f "$HOME/$i"  || -d "$HOME/$i")  && !(-f "$HOME/.dotfiles_backup/$i"  || -d "$HOME/.dotfiles_backup/$i") ]]; then
                cp -r $HOME/$i $HOME/.dotfiles_backup/$i
            fi
        done
    fi

    if [ "$dotfiles_folder" !=  "$(readlink -f "$HOME/.dotfiles")" ]; then
        if [ "$copy_repo" = true ]; then
            echo "-> Copying dotfiles folder to home folder"
            cp -r --no-preserve=ownership $dotfiles_folder $HOME/.dotfiles
        else
            echo "-> linking dotfiles folder"
            if [[ $dotfiles_folder == $HOME* ]]; then
                ln -sfT .${dotfiles_folder:${#HOME}} $HOME/.dotfiles
            else
                ln -sfT $dotfiles_folder $HOME/.dotfiles
            fi
        fi
    fi

    echo "-> Sourcing .bash_dotfiles_addon in .bashrc"
    if [ -z "$(grep -Fx "## Added by dotcli" $HOME/.bashrc)" ]; then
        printf "\n## Added by dotcli\n## Added by dotcli - end"  >> $HOME/.bashrc
    fi

    if [ -z "$(grep -Fx "    source \$HOME/.bashrc_dotfiles_addon" $HOME/.bashrc)" ]; then
        sed -i "/## Added by dotcli - end/iif [ -f \"\$HOME/.bashrc_dotfiles_addon\" ]; then\n    source \$HOME/.bashrc_dotfiles_addon\nfi" $HOME/.bashrc
    fi

    echo "-> linking dot files"
    for i in .tmux.conf .zshrc .vimrc .pylintrc .gitconfig .mpv .bashrc_dotfiles_addon .dotfiles_bin; do
        ln -sfT ./.dotfiles/$i $HOME/$i
    done

    echo "-> Linking NeoVim configuration file to Vim's"
    mkdir -p $HOME/.config
    mkdir -p $HOME/.vim
    ln -sfT ../.vim $HOME/.config/nvim
    ln -sfT ../.vimrc $HOME/.vim/init.vim
    
    ## Set oh my Zsh theme
    echo "-> Linking zsh theme"
    mkdir -p $HOME/.oh-my-zsh/themes/
    ln -sfT ../../.dotfiles/mytheme.zsh-theme $HOME/.oh-my-zsh/themes/mytheme.zsh-theme

    ## link to dotfile's notebook configuration file
    echo "-> Linking jupyter configuration"
    mkdir -p $HOME/.jupyter/nbconfig
    ln -sfT ../../.dotfiles/notebook.json $HOME/.jupyter/nbconfig/notebook.json
}

## set_zsh
## -------
subcommands+=( "set_zsh" )
descriptions_tmp+=( "set Zsh as the default shell." )

run_set_zsh() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Setting shell to Zsh"
    sudo chsh -s $(which zsh) $USER
}

## install_vim_plugins
## -------------------
subcommands+=( "install_vim_plugins" )
descriptions_tmp+=( "Install Vim plugins except for YouCompleteMe." )

run_install_vim_plugins() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install vim plugins"
    sed -i "s/^\([[:space:]]*\)\(Plugin[[:space:]]*'valloric\/youcompleteme'.*\)/\1\" \2/" $HOME/.vimrc
    vim -E -c "source $HOME/.vimrc" +PluginInstall +qall || true
    sed -i "s/^\([[:space:]]*\)\" \(Plugin[[:space:]]*'valloric\/youcompleteme'.*\)/\1\2/" $HOME/.vimrc
}

## install_youcompleteme
## ---------------------
subcommands+=( "install_youcompleteme" )
descriptions_tmp+=( "Install YouCompleteMe." )

run_install_youcompleteme() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Installing YouCompleteMe"
    sudo apt-get install -y cmake
    vim -E -c "source $HOME/.vimrc" +PluginInstall +qall || true
    if [ ! -f "$HOME/.vim/bundle/youcompleteme/third_party/ycmd/ycm_core.so" ]; then
        $HOME/.vim/bundle/youcompleteme/install.py --clang-completer
    fi
}

## link_root_vim
## -------------
subcommands+=( "link_root_vim" )
descriptions_tmp+=( "Link the .vim and .vimrc of the root folder to those of the current user." )

run_link_root_vim() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [ ! -z $USER ] && [ "$USER" != "root" ]; then
        echo "-> linking root's .vimrc and .vim"
        sudo ln -sfT $HOME/.vimrc /root/.vimrc
        sudo ln -sfT $HOME/.vim /root/.vim
    fi
}

## create_python_venv
## ------------------
subcommands+=( "create_python_venv" )
descriptions_tmp+=( "Create a Python virtual environment." )

run_create_python_venv() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [ ! -d "$HOME/venv" ]; then
        echo "-> Create python vitualenv"
        sudo pip3 install -U virtualenv
        virtualenv $HOME/venv --no-site-packages
        source $HOME/venv/bin/activate
    fi

    add_line $HOME/.bashrc_addon "## Create an alias of the vitrual python environment and activate it" "Python virtual environment"
    add_line $HOME/.bashrc_addon "## =================================================================" "Python virtual environment"
    add_line $HOME/.bashrc_addon "VIRTUAL_ENV_DISABLE_PROMPT=1" "Python virtual environment"
    add_line $HOME/.bashrc_addon "alias pyenv=\"source \$HOME/venv/bin/activate\"" "Python virtual environment"
    add_line $HOME/.bashrc_addon "pyenv" "Python virtual environment"
}

## install_python_basic
## --------------------
subcommands+=( "install_python_basic" )
descriptions_tmp+=( "Install basic Python packages." )

run_install_python_basic() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install python packages"
    ## dependencies For matplotlib
    sudo apt-get install -y -qq \
        libfreetype6-dev \
        libpng-dev \
        python-qt4 \
        python3-pyqt5
    pip3 install pip==18.1
    hash -r pip
    pip3 install -U \
        ipython==7.0.1 \
        numpy==1.15.2 \
        scipy==1.1.0 \
        matplotlib==3.0.0 \
        pandas==0.23.4 \
        pyyaml==3.13
    add_line $HOME/.bashrc_addon "export MPLBACKEND=Agg" "Python"
}

## setup_jupyter
## -------------
subcommands+=( "setup_jupyter" )
descriptions_tmp+=( "Setup Jupyter notbook" )

run_setup_jupyter() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Setting up Jupyter"
    ## Install Jupyter Notebook
    pip3 install jupyter==1.0.0
    ## Enable widgets
    jupyter nbextension enable --py widgetsnbextension
    ## Install extensions
    pip3 install jupyter_contrib_nbextensions
    jupyter contrib nbextension install --user
    ## Enable configurator (Jupyter extension webgui)
    jupyter nbextensions_configurator enable
    ## link to dotfile's notebook configuration file
    ln -sfT $HOME/.dotfiles/notebook.json $HOME/.jupyter/nbconfig/notebook.json
    ## Setup extra extensions
    ln -sfT $HOME/.dotfiles/jupyter_extensions $HOME/jupyter_extensions
    ## Setup vim binding
    jupyter nbextension install $HOME/jupyter_extensions/vim_config --user && \
    jupyter nbextension enable vim_config/main

    ## Install Jupyter Lab
    ## -------------------
    pip3 install jupyterlab==0.4.0
    jupyter serverextension enable --py jupyterlab --user

    ## Set theme
    ## ---------
    pip3 install jupyterthemes==0.19.6
    # jt -t oceans16 -ofs 12 -cellw 88% -T -N
    # ## Fix bug in margin size
    # sed -i "1idiv.output_area {\n  display: -webkit-box;\n  padding: 30px;\n}" $HOME/.jupyter/custom/custom.css
}

## install_docker
## --------------
subcommands+=( "install_docker" )
descriptions_tmp+=( "Install Docker." )

run_install_docker() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install docker"
    if [ "$(lsb_release -r | awk '{print $2}')" == "14.04" ]; then
        sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual  # allow Docker to use the aufs storage
    fi
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common  # allow apt to use a repository over HTTPS
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  # Add Docker’s official GPG key
    ## Verify that the key fingerprint is 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88: sudo apt-key fingerprint 0EBFCD88
    ubuntu_codename="$(lsb_release -cs)"
    if [ "$ubuntu_codename" == "cosmic" ]; then
        ubuntu_codename="bionic"
    fi
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $ubuntu_codename stable"
    sudo apt-get update || true
    sudo apt-get install -y docker-ce
    ## Test docker installation: sudo docker run hello-world

    sudo groupadd docker || true
    sudo usermod -aG docker $USER

    ## ==========================
    echo "-> Install docker compose"
    curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose >  /dev/null
    sudo chmod +x /usr/local/bin/docker-compose
    sudo curl -L https://raw.githubusercontent.com/docker/compose/1.23.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
}

## install_nvidia_docker
## ---------------------
subcommands+=( "install_nvidia_docker" )
descriptions_tmp+=( "Install NVIDIA-Docker." )

run_install_nvidia_docker() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install nvidia-docker"
    # If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
    sudo docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
    sudo apt-get purge -y nvidia-docker || true

    # Add the package repositories
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    if [ "$distribution" == "ubuntu18.10" ]; then
        distribution="ubuntu18.04"
    fi
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update

    # Install nvidia-docker2 and reload the Docker daemon configuration
    sudo apt-get install -y nvidia-docker2
    # sudo sed -i "2i \    \"default-runtime\": \"nvidia\"," /etc/docker/daemon.json
    sudo pkill -SIGHUP dockerd

    # # Test nvidia-smi with the latest official CUDA image
    # sudo docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi

    # if [ -z "$(sudo docker network ls | grep docknet)" ]; then
    #     echo "-> Create docker network"
    #     sudo docker network create --driver bridge --subnet 172.18.0.0/16 docknet
    # fi
}

## install_openvpn_client
## ----------------------
subcommands+=( "install_openvpn_client" )
descriptions_tmp+=( "Install OpenVPN client." )

run_install_openvpn_client() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Installing OpenVPN"
    sudo apt-get install -y openvpn
    sudo wget https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved -P /etc/openvpn/scripts/
    sudo chmod a+x /etc/openvpn/scripts/update-systemd-resolved
}

## setup_gui_stuff
## ---------------
subcommands+=( "setup_gui_stuff" )
descriptions_tmp+=( "Setup and install packages for a machine with a GUI." )

run_setup_gui_stuff() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    ## Tip: To capture changes made to gnome in the terminal run "dconf watch /"

    ## Matplotlib backend
    ## ==================
    echo "-> Change MatPlotLibs's default backend"
    change_line $HOME/.bashrc_addon "^export MPLBACKEND=.*$" "export MPLBACKEND=Qt5Agg" 

    # ## Unity
    # ## ==========================
    # echo "-> Don\'t suspend on lid close when plugged in"
    # gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing

    # # ## ==========================
    # # echo "-> Set touchpad speed"
    # # gsettings set ???

    # ## ==========================
    # echo "-> Set favorite apps"
    # gsettings set com.canonical.Unity.Launcher favorites "['application://ubiquity.desktop', 'application://org.gnome.Terminal.desktop', 'application://org.gnome.Nautilus.desktop', 'application://google-chrome.desktop', 'unity://running-apps', 'unity://expo-icon', 'unity://devices']"

    # ## ==========================
    # echo "-> Install Indicator-mutiload"
    # sudo apt-get install -y indicator-multiload
    # gsettings set de.mh21.indicator-multiload.general settings-version "uint32 3"
    # gsettings set de.mh21.indicator-multiload.general autostart true
    # gsettings set de.mh21.indicator-multiload.general color-scheme 'traditional'
    # gsettings set de.mh21.indicator-multiload.graphs.cpu enabled true
    # gsettings set de.mh21.indicator-multiload.traces.cpu1 color 'traditional:cpu1'
    # gsettings set de.mh21.indicator-multiload.traces.cpu2 color 'traditional:cpu2'
    # gsettings set de.mh21.indicator-multiload.traces.cpu3 color 'traditional:cpu3'
    # gsettings set de.mh21.indicator-multiload.traces.cpu4 color 'traditional:cpu4'
    # gsettings set de.mh21.indicator-multiload.graphs.mem enabled true
    # gsettings set de.mh21.indicator-multiload.traces.mem1 color 'traditional:mem1'
    # gsettings set de.mh21.indicator-multiload.traces.mem2 color 'traditional:mem2'
    # gsettings set de.mh21.indicator-multiload.traces.mem3 color 'traditional:mem3'
    # gsettings set de.mh21.indicator-multiload.traces.mem4 color 'traditional:mem4'
    # gsettings set de.mh21.indicator-multiload.graphs.net enabled true
    # gsettings set de.mh21.indicator-multiload.traces.net1 color 'traditional:net1'
    # gsettings set de.mh21.indicator-multiload.traces.net2 color 'traditional:net2'
    # gsettings set de.mh21.indicator-multiload.traces.net3 color 'traditional:net3'
    # gsettings set de.mh21.indicator-multiload.graphs.swap enabled true
    # gsettings set de.mh21.indicator-multiload.traces.swap1 color 'traditional:swap1'
    # gsettings set de.mh21.indicator-multiload.graphs.load enabled true
    # gsettings set de.mh21.indicator-multiload.traces.load1 color 'traditional:load1'
    # gsettings set de.mh21.indicator-multiload.graphs.disk enabled true
    # gsettings set de.mh21.indicator-multiload.traces.disk1 color 'traditional:disk1'
    # gsettings set de.mh21.indicator-multiload.traces.disk2 color 'traditional:disk2'
    # gsettings set de.mh21.indicator-multiload.general background-color "traditional:background"

    # # ## ==========================
    # # echo "-> Disable sticky edges"
    # # dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-capture-mouse false

    ## GNOME
    ## =====
    echo "Install Gnome Tweak tool"
    sudo add-apt-repository universe
    sudo apt install -y gnome-tweak-tool

    ## ==========================
    echo "-> Set Alt-Tab to switch windows (and not applications)"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt><Super>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt><Super>Tab']"

    ## ==========================
    echo "-> Disable two fingers as right click"
    gsettings set org.gnome.desktop.peripherals.touchpad click-method areas

    ## ==========================
    echo "-> Disable natural-scroll"
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false

    ## ==========================
    echo "-> Disable tap to click"
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false

    ## ==========================
    echo "-> Set power button to suspend"
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action suspend

    ## ==========================
    echo "-> Set idle delay to 10 min"
    gsettings set org.gnome.desktop.session idle-delay 600

    ## ==========================
    echo "-> Show battery percentage"
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    ## ==========================
    echo "-> Don\'t suspend on lid close"
    gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing

    ## ==========================
    echo "-> Set touchpad speed"
    gsettings set org.gnome.desktop.peripherals.touchpad speed 1.0

    ## ==========================
    echo "-> Show dock on all screens"
    gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

    ## ==========================
    echo "-> Set favorite apps"
    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'gnome-control-center.desktop', 'google-chrome.desktop', 'pycharm-community_pycharm-community.desktop', 'mendeleydesktop.desktop', 'spotify_spotify.desktop']"

    ## ==========================
    echo "-> Install system-monitor indicator"
    sudo apt-get install -y gir1.2-gtop-2.0 gir1.2-networkmanager-1.0  gir1.2-clutter-1.0
    sudo apt-get install -y chrome-gnome-shell
    # gsettings set org.gnome.shell.extensions.system-monitor cpu-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor memory-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor swap-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor net-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor disk-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor gpu-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor thermal-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor fan-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor freq-graph-width 50
    # gsettings set org.gnome.shell.extensions.system-monitor battery-graph-width 50

    ## ==========================
    echo "-> Add Hebrew keyboard"
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'il')]"
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L']"

    # ## ==========================
    # default_terminal_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
    # if [ -z "$(gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${default_terminal_id}/ font | grep Powerline)" ]; then
    #     echo "-> Install powerline fonts"
    #     git clone https://github.com/powerline/fonts.git /tmp/fonts --depth=1
    #     pushd /tmp/fonts
    #     ./install.sh
    #     popd
    #     rm -rf /tmp/fonts
    #     gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${default_terminal_id}/ use-system-font false
    #     gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${default_terminal_id}/ font "Droid Sans Mono Dotted for Powerline 10"
    # fi

    ## ==========================
    if [ -z "$(cat $HOME/.dir_colors/dircolors | grep gruvbox)" ]; then
        echo "-> Set colorscheme in Gnome terminal"
        git clone https://github.com/metalelf0/gnome-terminal-colors.git /tmp/gnome-terminal-colors
        default_terminal_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
        /tmp/gnome-terminal-colors/install.sh -s gruvbox-dark -p ":$default_terminal_id" --install-dircolors
        rm -rf /tmp/gnome-terminal-colors
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${default_terminal_id}/ use-theme-transparency false
        echo "## gruvbox-dark theme" >> $HOME/.dir_colors/dircolors
    fi

    ## ==========================
    echo "-> Install OpenVPN Network manager support"
    sudo apt-get install -y openvpn network-manager-openvpn network-manager-openvpn-gnome

    ## ==========================
    echo "-> Install GVim"
    sudo apt-get install -y vim-gnome

    ## ==========================
    echo "-> Install GParted"
    sudo apt-get install -y gparted

    ## ==========================
    echo "-> Install CompizConfig"
    sudo apt-get install -y compizconfig-settings-manager

    ## ==========================
    echo "-> Install vlc"
    sudo apt-get install -y vlc

    ## ==========================
    echo "-> Install mpv"
    sudo apt-get install -y mpv

    ## ==========================
    echo "-> Install Gwenview"
    sudo apt-get install -y gwenview

    ## ==========================
    if [ ! -x "$(command -v google-chrome)" ]; then
        echo "-> Install chrome"
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
        sudo apt-get update
        sudo apt-get install google-chrome-stable
    fi

    ## ==========================
    if [ ! -x "$(command -v mendeleydesktop)" ]; then
        echo "-> Install Medndely"
        sudo apt-get install -y gconf2
        pushd /tmp
        wget https://www.mendeley.com/repositories/ubuntu/stable/amd64/mendeleydesktop-latest
        sudo dpkg -i mendeleydesktop-latest
        popd
        rm /tmp/mendeleydesktop-latest
    fi

    ## ==========================
    echo "-> Install PyCharm"
    sudo snap install pycharm-community --classic

    ## ==========================
    echo "-> Install MeshLab"
    sudo snap install meshlab

    ## ==========================
    echo "-> Install Spotify"
    sudo snap install spotify
}

## install_ocamlfuse
## -----------------
subcommands+=( "install_ocamlfuse" )
descriptions_tmp+=( "Install ocamlfuse (mounts Google drive locally)." )

run_install_ocamlfuse() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Install google-drive-ocamlfuse and mount Goggle drive"
    sudo add-apt-repository -y ppa:alessandro-strada/ppa
    sudo apt-get update
    sudo apt-get install google-drive-ocamlfuse

    sudo mkdir -p /network/google-drive
    sudo chmod 777 /network/google-drive

    ## Login once using:
    ## google-drive-ocamlfuse -label personal
    ## mount drive using
    ## google-drive-ocamlfuse -label personal /network/google-drive
}

## mount
## -----
subcommands+=( "mount" )
descriptions_tmp+=( "Setup mount." )

run_mount() {
    device_id=""
    mount_location=""
    format_device=false
    mount_type=ext4
    mount_options="defaults,nofail,discard"
    change_owner=false
    mount_owner=$USER

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand device_id mount_location [-t mount_type] [-o mount_options] [-c mount_owner] [-f]"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo "Options:"
        echo "    device_id                     The device identifier"
        echo "    mount_location                The mounting location"
        echo "    -t mount_type                 The file system type, Default: \"$mount_type\""
        echo "    -o mount_options              Additional mount options. Default: \"$mount_options\""
        echo "    -c mount_owner                Change folders and files owner."
        echo "    -f                            format device."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -lt 2 ]; then
        echo "Error: $app_name $subcommand expects a device id and a mounting location" 1>&2
        usage
        exit 1
    fi

    device_id=$1; shift
    mount_location=$1; shift
    while getopts "t:o:c:f" opt; do
        case $opt in
            t)
                mount_type=$OPTARG
                ;;
            o)
                mount_options=$OPTARG
                ;;
            c)
                change_owner=true
                mount_owner=$OPTARG
                ;;
            f)
                format_device=true
                ;;
            h)
                usage
                exit 0
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    if [ "$format_device" = true ]; then
        echo "-> Formatting device"
        sudo mkfs.$mount_type -f $device_id
    fi

    if [ ! -d "$mount_location" ]; then
        echo "-> Creating mount folder"
        sudo mkdir -p $mount_location
    fi

    echo "-> Adding mounted folder to fstab"
    add_line /etc/fstab "$device_id $mount_location $mount_type $mount_options 0 0"

    sudo mount -a

    if [ "$change_owner" = true ]; then
        echo "-> Changing owner"
        sudo chown $mount_owner:$mount_owner -r $mount_location
    fi
}

## add_host
## --------
subcommands+=( "add_host" )
descriptions_tmp+=( "Add an IP and host to the hosts file." )

run_add_host() {
    host_to_add=$1
    ip_to_add=2

    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand host ip"
        echo "   or: $app_name $subcommand -h          to print this help message"
        echo "Options:"
        echo "    host                          The host's domain name"
        echo "    ip                            The host's IP"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -lt 2 ]; then
        echo "Error: $app_name $subcommand expects an host and IP" 1>&2
        usage
        exit 1
    fi

    host_to_add=$1; shift
    ip_to_add=$1; shift

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Adding host to /etc/hosts"
    add_line /etc/hosts "$ip_to_add $host_to_add"
}

## clean_up_dotfiles
## -----------------
subcommands+=( "clean_up_dotfiles" )
descriptions_tmp+=( "Restore the backed up dotfiles." )

run_clean_up_dotfiles() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Cleaning up"

    for i in .tmux.conf .zshrc .vimrc .pylintrc .gitconfig .mpv .bashrc_dotfiles_addon .config/nvim .vim/init.vim .jupyter/nbconfig/notebook.json; do
        if [[ -f "$HOME/$i"  || -d "$HOME/$i"  ]]; then
            rm -r $HOME/$i
        fi
        if [[ -f "$HOME/.dotfiles_backup/$i" || -d "$HOME/.dotfiles_backup/$i" ]]; then
            cp -r $HOME/.dotfiles_backup/$i $HOME/$i
        fi
    done
    sed -i '/^## Added by dotcli$/,/^## Added by dotcli - end$/d' $HOME/.bashrc
    rm -rf $HOME/.dotfiles
    rm -r $HOME/.dotfiles_backup
}

## install
## -------
subcommands+=( "install" )
descriptions_tmp+=( "Install the dotcli tool" )

run_install() {
    ## CLI
    ## ---
    usage () {
        echo descriptions[$subcommand]
        echo ""
        echo "usage: $app_name $subcommand username"
        echo "   or: $app_name $subcommand -h          to print this help message"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi
    
    ## Run
    ## ---
    echo "-> Creating a symbolic link to ${dotfiles_folder}/dotcli.sh at /usr/bin/dotcli"
    sudo ln -sfT ${dotfiles_folder}/dotcli.sh /usr/bin/dotcli

    cat <<EOL | sudo tee /etc/bash_completion.d/dotcli_completion > /dev/null
#!/usr/bin/env bash

_dotcli() {
    subcommands=\$(${dotfiles_folder}/dotcli.sh _print_subcommands)
    COMPREPLY=(\$(compgen -W "\$subcommands" "\${COMP_WORDS[1]}"))
}
complete -F _dotcli dotcli
EOL
    
    cat <<EOL | sudo tee /usr/share/zsh/vendor-completions/_dotcli > /dev/null
#compdef dotcli

source ${dotfiles_folder}/dotcli.sh
_zsh_completion
EOL

}

## _bash_completion
## ================
subcommands+=( "_print_subcommands" )
descriptions_tmp+=( "" )

run__print_subcommands() {
    echo "${subcommands[@]}"
} 

## _zsh_completion
## ===============
_zsh_completion() {
    ret=1

    declare -a subcmds
    for (( i=1; i<=${#subcommands[@]}; i++ )); do
        subcmds+=( "${subcommands[$(($i))]}:${descriptions_tmp[$(($i))]}" )
    done

    _describe 'command' subcmds && ret=0

    return ret
} 

## Main
## =====
declare -A descriptions
len=${#distro[@]}
for (( i=0; i<${#subcommands[@]}; i++ )); do
    subcommand=${subcommands[$(($i))]}
    description=${descriptions_tmp[$(($i))]}
    descriptions["$subcommand"]=$description
done

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ## Script is a subshell.
    main_cli $@
fi