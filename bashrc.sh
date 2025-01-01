welcome_message="ubuntu"
lolcat_enabled=0
CENTERED_WELCOME=1
CUSTOM_PINK='\e[38;2;228;171;212m'
CUSTOM_GRAY='\e[38;2;196;189;210m'
NC='\e[0m'
WELCOME_COLOR=$CUSTOM_GRAY

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
    if [ "$welcome_message" = "start" ]; then
        figlet -f red_phoenix "start" | lolcat -S 13 | center_text
    elif [ "$welcome_message" = "reaper" ]; then
        if [[ $lolcat_enabled -eq 1 ]]; then
            cat ~/.config/nvim/ascii/reaper.txt | lolcat -S 35 -p 100 -F 0.05 | center_text
        else
            echo -e "${WELCOME_COLOR}$(cat ~/.config/nvim/ascii/reaper.txt)${NC}" | center_text
        fi
    elif [ "$welcome_message" = "swords" ]; then
        if [[ $lolcat_enabled -eq 1 ]]; then
            cat ~/.config/nvim/ascii/sword.txt | lolcat -S 35 -p 100 -F 0.05 | center_text
        else
            echo -e "${WELCOME_COLOR}$(cat ~/.config/nvim/ascii/sword.txt)${NC}" | center_text
        fi
    elif [ "$welcome_message" = "dragon" ]; then
        if [[ $lolcat_enabled -eq 1 ]]; then
            cat ~/.config/nvim/ascii/dragon.txt | lolcat -S 35 -p 100 -F 0.05 | center_text
        else
            echo -e "${WELCOME_COLOR}$(cat ~/.config/nvim/ascii/dragon.txt)${NC}" | center_text
        fi
    elif [ "$welcome_message" = "ubuntu" ]; then
        if [[ $lolcat_enabled -eq 1 ]]; then
            cat ~/.config/nvim/ascii/ubuntu.txt | lolcat -S 35 -p 100 -F 0.05 | center_text
        else
            echo -e "${WELCOME_COLOR}$(cat ~/.config/nvim/ascii/ubuntu.txt)${NC}" | center_text
        fi
    echo; echo
    fi
}

