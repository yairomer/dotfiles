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
        echo "A CLI tool to setup dotfiles configurations"
        echo ""
        echo "usage: $app_name  <command> [<options>]"
        echo "   or: $app_name -h         to print this help message."
        echo ""
        echo "Commands"
        echo "    run                     Run a list of setup stages."
        echo "    switch_to_ssh           Switch dotfiles repository's upstream to be SSH based."
        echo "    clean_up                Restore the backed up dotfiles."
        echo "Use $app_name <command> -h for specific help on each command."
    }
    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
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

    case "$subcommand" in
        run)
            run_cli $@
            ;;
        switch_to_ssh)
            switch_to_ssh_cli $@
            ;;
        clean_up)
            clean_up_cli $@
            ;;
        *)
            echo "Error: unknown command $subcommand" 1>&2
            usage
            exit 1
    esac
}

run_cli() {
    declare -A stages=( 
                        ["install"]=false \
                        ["install_omz"]=false \
                        ["link_dotfiles"]=false \
                        ["vim_plugins"]=false \
                        ["youcompleteme"]=false \
                        ["set_zsh"]=false \
                        ["link_root_vim"]=false \
                        )
    copy_repo=false
    invert_selection=false
    usage () {
        echo "Run a list of setup stages."
        echo ""
        echo "usage: $app_name $subcommand [<options>] stage1,stage2,..."
        echo "   or: $app_name $subcommand -h"
        echo "Options:"
        echo "    -a                      Run all stages but dose listed."
        echo "    -c                      Copy the current dotfiles folder to the home folder instead of creating a link."
        echo ""
        echo "List of stages:"
        echo "    install                 Install Vim + NeoVim + TMUX + Zsh."
        echo "    install_omz             Install Oh-My-Zsh and plugins."
        echo "    link_dotfiles           Create links in home folder to the dotfiles in the repository."
        echo "    vim_plugins             Install Vim plugins except forYouCompleteMe."
        echo "    youcompleteme           Install YouCompleteMe."
        echo "    set_zsh                 set Zsh as the default shell."
        echo "    link_root_vim           Link the .vim and .vimrc of the root folder to those of the current user."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "ac" opt; do
        case $opt in
            a)
                for stage in "${!stages[@]}"; do
                    stages[$stage]=true
                done
                invert_selection=true
                ;;
            c)
                copy_repo=false
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
        stages_list=$1; shift
        IFS=',' read -ra stages_list <<< "$stages_list"
        for stage in "${stages_list[@]}"; do
            if ! is_valid_stage $stage; then
                echo "Error: Invalid stage: $stage" 1>&2
                exit 1
            fi
            if [ "$invert_selection" = true ]; then
                stages[$stage]=false
            else
                stages[$stage]=true
            fi
        done
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    if [ "${stages["install"]}" = true ]; then
        install
    fi
    if [ "${stages["install_omz"]}" = true ]; then
        install_omz
    fi
    if [ "${stages["link_dotfiles"]}" = true ]; then
        link_dotfiles
    fi
    if [ "${stages["vim_plugins"]}" = true ]; then
        vim_plugins
    fi
    if [ "${stages["youcompleteme"]}" = true ]; then
        setup_youcompleteme
    fi
    if [ "${stages["set_zsh"]}" = true ]; then
        set_zsh
    fi
    if [ "${stages["link_root_vim"]}" = true ]; then
        link_root_vim
    fi

    if [ "$restart_ssh_daemon" = true ]; then
        restart_ssh_daemon
    fi
}

switch_to_ssh_cli() {
    usage () {
        echo "Switch dotfiles repository's upstream to be SSH based."
        echo ""
        echo "usage: $app_name $subcommand"
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

    switch_to_ssh
}

clean_up_cli() {
    usage () {
        echo "Restore the backed up dotfiles."
        echo ""
        echo "usage: $app_name $subcommand"
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

    clean_up
}

## Auxiliaries
## ===========
dotfiles_dir="$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )"

is_valid_stage() {
    # Usage: is_valid_state state_name
    local stage=$1
    local in=1
    for curr_stage in "${!stages[@]}"; do
        if [[ $curr_stage == $stage ]]; then
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
        printf "\n## $title\n$string\n## $title - end\n"  >> "$1"
    else
        if [ -z "$(grep -Fx "$string" "$filename")" ]; then
            sed -i "/## $title - end/i$string" $filename
        fi
    fi
}

## Run
## ===
switch_to_ssh(){
    pushd $dotfiles_dir
    git remote set-url origin git@github.com:yairomer/dotfiles.git
    popd

}

install() {
    echo "-> Install basic packages"
    # sudo add-apt-repository -y ppa:pkg-vim/vim-daily
    # sudo apt-get update || true
    sudo apt-get install -y -qq \
        vim \
        neovim \
        tmux \
        zsh
}

install_omz() {
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

link_dotfiles() {
    if [ ! -d "$HOME/.dotfiles_backup" ]; then
        echo "-> backing up dotfiles"
        mkdir $HOME/.dotfiles_backup
        mkdir $HOME/.dotfiles_backup/.config
        mkdir $HOME/.dotfiles_backup/.vim
        mkdir -p $HOME/.dotfiles_backup/.jupyter/nbconfig/
        for i in .bashrc .tmux.conf .zshrc .vimrc .pylintrc .gitconfig .mpv .config/nvim .vim/init.vim .jupyter/nbconfig/notebook.json; do
            if [[ (-f "$HOME/$i"  || -d "$HOME/$i")  && !(-f "$HOME/.dotfiles_backup/$i"  || -d "$HOME/.dotfiles_backup/$i") ]]; then
                cp -r $HOME/$i $HOME/.dotfiles_backup/$i
            fi
        done
    fi

    if [ "$dotfiles_dir" !=  "$(cd $HOME/.dotfiles && pwd)" ]; then
        if [ "$copy_repo" = true]; then
            echo "-> Copying dotfiles folder to home folder"
            cp -r --no-preserve=ownership $dotfiles_dir $HOME/.dotfiles
        else
            echo "-> linking dotfiles folder"
            if [[ $dotfiles_dir == $HOME* ]]; then
                ln -sfT .${dotfiles_dir:${#HOME}} $HOME/.dotfiles
            else
                ln -sfT $dotfiles_dir $HOME/.dotfiles
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
    for i in .tmux.conf .zshrc .vimrc .pylintrc .gitconfig .mpv .bashrc_dotfiles_addon; do
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

vim_plugins() {
    echo "-> Install vim plugins"
    sed -i "s/^\([[:space:]]*\)\(Plugin[[:space:]]*'valloric\/youcompleteme'.*\)/\1\" \2/" $HOME/.vimrc
    vim -E -c "source $HOME/.vimrc" +PluginInstall +qall || true
    sed -i "s/^\([[:space:]]*\)\" \(Plugin[[:space:]]*'valloric\/youcompleteme'.*\)/\1\2/" $HOME/.vimrc
}

set_zsh() {
    echo "-> Setting shell to Zsh"

    sudo chsh -s $(which zsh) $USER
}

link_root_vim() {
    if [ ! -z $USER ] && [ "$USER" != "root" ]; then
        echo "-> linking root's .vimrc and .vim"
        sudo ln -sfT $HOME/.vimrc /root/.vimrc
        sudo ln -sfT $HOME/.vim /root/.vim
    fi
}

setup_youcompleteme() {
    echo "-> Installing YouCompleteMe"

    sudo apt-get install -y cmake
    vim -E -c "source $HOME/.vimrc" +PluginInstall +qall || true
    if [ ! -f "$HOME/.vim/bundle/youcompleteme/third_party/ycmd/ycm_core.so" ]; then
        $HOME/.vim/bundle/youcompleteme/install.py --clang-completer
    fi
}

clean_up() {
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

main_cli $@
