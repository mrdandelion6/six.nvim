NEOVIM_PATH="$HOME/.config/nvim/"

# add colors here
CUSTOM_PINK='\e[38;2;228;171;212m'
CUSTOM_GRAY='\e[38;2;196;189;210m'
NC='\e[0m'

# configure these as you like
lolcat_enabled=0
CENTERED_WELCOME=1
WELCOME_COLOR=$CUSTOM_GRAY
ascii_path="${NEOVIM_PATH}bash/ascii_art/"
ascii_art="reaper2.txt"

center_text() {
    local should_center=$CENTERED_WELCOME

    if [[ $should_center -eq 0 ]]; then
        cat -
        return
    fi

    term_width=$(tput cols)

    # Read input line by line while preserving colors
    while IFS= read -r line; do
        # Strip ANSI color codes for width calculation
        plain_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        # Calculate padding
        padding=$(( (term_width - ${#plain_line}) / 2 ))
        # Add padding before the line
        printf "%${padding}s%s\n" "" "$line"
    done
}

welcome() {
    echo; echo
    if [ -f "$ascii_path$ascii_art" ]; then
        if [[ $lolcat_enabled -eq 1 ]]; then
            cat "$ascii_path$ascii_art" | lolcat -S 35 -p 100 -F 0.05 | center_text
        else
            echo -e "${WELCOME_COLOR}$(cat "$ascii_path$ascii_art")${NC}" | center_text
        fi
    else
        figlet -f red_phoenix "start" | lolcat -S 13 | center_text
    fi
    echo; echo
}

notify_nvim() {
    printf '\033]51;%s\007' $(pwd)
}

function cd() {
    builtin cd "$@"
    if [ -n "$NVIM" ]; then
        notify_nvim
    fi
}
