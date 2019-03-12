## Auxiliary
## =========

## Docker prompt
## -------------
ZSH_THEME_DOCKER_PROMPT="$fg_bold[white]$bg[red]DOCKER$reset_color-"

function get_docker_prompt_info() {
    if [ ! -z "$(awk -F/ '$2 == "docker"' /proc/self/cgroup)" ]; then
        echo $ZSH_THEME_DOCKER_PROMPT
    fi
}

## git prompt
## ----------
ZSH_THEME_GIT_PROMPT_PREFIX=" $fg_bold[white]on %{$fg_bold[yellow]%}⎇  "
ZSH_THEME_GIT_PROMPT_SUFFIX="$reset_color"
ZSH_THEME_GIT_PROMPT_DIRTY="$fg[red]✗"
ZSH_THEME_GIT_PROMPT_CLEAN=""

## python virtual environment prompt
## ---------------------------------
VIRTUAL_ENV_DISABLE_PROMPT=true
ZSH_THEME_VIRTUALENV_PROMPT_PREFIX=" $fg_bold[white]using $fg_bold[cyan]"
ZSH_THEME_VIRTUALENV_PROMPT_SUFFIX="$reset_color"

function virtualenv_prompt_info2() {
    if [ ! -z "$VIRTUAL_ENV" ]; then
        local virtual_env_name="$(basename $VIRTUAL_ENV)"
        echo $ZSH_THEME_VIRTUALENV_PROMPT_PREFIX$virtual_env_name$ZSH_THEME_VIRTUALENV_PROMPT_SUFFIX
    else
        echo ""
    fi
}

## vi mode prompt
## --------------
# ZSH_THEME_VIMODE_PROMPT_PREFIX=" $fg_bold[black]$bg[yellow] "
# ZSH_THEME_VIMODE_PROMPT_SUFFIX=" $reset_color"
# ZSH_THEME_VIMODE_PROMPT_NORMAL="NORMAL MODE"
# ZSH_THEME_VIMODE_PROMPT_INSERT="INSERT MODE"

ZSH_THEME_VIMODE_PROMPT_PREFIX=""
ZSH_THEME_VIMODE_PROMPT_SUFFIX=""
ZSH_THEME_VIMODE_PROMPT_NORMAL="✍ "
ZSH_THEME_VIMODE_PROMPT_INSERT="%{$fg_bold[white]%}\$%{$reset_color%} "

function vimode_prompt_info() {
    case "$VIMODE" in
        normal)
            echo $ZSH_THEME_VIMODE_PROMPT_PREFIX$ZSH_THEME_VIMODE_PROMPT_NORMAL$ZSH_THEME_VIMODE_PROMPT_SUFFIX
            ;;
        insert)
            echo $ZSH_THEME_VIMODE_PROMPT_PREFIX$ZSH_THEME_VIMODE_PROMPT_INSERT$ZSH_THEME_VIMODE_PROMPT_SUFFIX
            ;;
        *)
            echo ""
    esac
}

zle-keymap-select() {
    if [[ $KEYMAP = vicmd ]]; then
        VIMODE=normal
    else
        VIMODE=insert
    fi

    zle reset-prompt
}
zle -N zle-keymap-select

## chpwd
## =====
chpwd() {
    echo ""
    print -P '    $fg[cyan] ━━━━━ $reset_color 📂 $fg[green]Current dirctory$reset_color: $fg_bold[white]%d$reset_color $fg[cyan] ━━━━━ $reset_color'
    ls -a
    print -P '    $fg[cyan] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ $reset_color'
}

## precmd
## ======
precmd() {
    exit_code=$?
    export VIMODE=insert
    echo ""
    if [ $exit_code -ne 0 ]; then
        print -P '$fg_bold[red]✗ exit code: $exit_code $reset_color😲'
        echo ""
    fi
    print -P '$fg_bold[green]➜  [%h]$reset_color (%T) $fg_bold[cyan]%n$fg_bold[white]@$(get_docker_prompt_info)$fg_bold[blue]%m$fg_bold[white]:$fg_bold[green]%5~$reset_color$(git_prompt_info)$(virtualenv_prompt_info2)'
}

## Prompt
## ======
PROMPT='$(vimode_prompt_info)'

