# WELCOME MESSAGE CONFIGURATION
# config for what you want your shell to print when it starts. not specific to
# neovim. just in case you wanna copy my aesthetic ;)

# here we have some constants
# add colors here
CUSTOM_PINK='\e[38;2;228;171;212m'
CUSTOM_GRAY='\e[38;2;196;189;210m'
NC='\e[0m'

# configure these as you like
fastfetch=true # if you want to print fastfetch
CENTERED_WELCOME=1
WELCOME_COLOR=$CUSTOM_GRAY

# change this to a different location if you want. if you want to use the same
# art as i do , then you can clone my .dotfiles repo in the path below. see the
# README for .dotfiles repo.
ascii_path="$HOME/.dotfiles/ascii_art/"
ascii_art="reaper2.txt"

# function that prints given text centered in the terminal for whatever width.
center_text() {
    local should_center=$CENTERED_WELCOME

    if [[ $should_center -eq 0 ]]; then
        cat -
        return
    fi

    term_width=$(tput cols)

    # read input line by line while preserving colors
    while IFS= read -r line; do
        # strip ansi color codes for width calculation
        plain_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        # calculate padding
        padding=$(( (term_width - ${#plain_line}) / 2 ))

        # add padding before the line
        printf "%${padding}s%s\n" "" "$line"
    done
}

# print the welcome message , whether fastfetch or ascii art
welcome() {
    echo; echo
    if [ "$is_arch" = true ]; then
        fastfetch
    elif [ -f "$ascii_path$ascii_art" ]; then
        echo -e "${WELCOME_COLOR}$(cat "$ascii_path$ascii_art")${NC}" |
            center_text
    fi
    echo; echo
}

# NVIM CONFIGS
# here are some actual functions needed for my nvim config if you want certain
# features.

# for launching nvim with right venv enabled. needed if using molten.nvim.
nvim() {
    if [[ "$VIRTUAL_ENV" != "neovim" ]]; then
        if [ -n "$VIRTUAL_ENV" ]; then
            deactivate
        fi
        if [ -f "$envdir/neovim" ]; then
            actenv 'neovim'
        fi
    fi
    command nvim "$@"
}

# for updating the buffer title for terminal buffers. sets title to pwd and
# updates on cd.
notify_nvim() {
    # send specific signal to neovim ONLY if this terminal is spawned inside it
    if [ -n "$NVIM" ]; then
        printf '\033]51;%s\007' $(pwd)
    fi
}

function cd() {
    builtin cd "$@"
    notify_nvim
}

# also run it at the moment your terminal loads.
notify_nvim
