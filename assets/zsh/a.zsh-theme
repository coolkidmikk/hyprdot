# 1. Enable dynamic prompts (Crucial for functions to run)
setopt PROMPT_SUBST

# Status symbol
status_symbol() {
    echo $'\u25cf'
}

status_ok() {
    echo "%F{white}$(status_symbol)%f"
}

status_err() {
    echo "%F{red}$(status_symbol)%f"
}

# Auto-select color based on last status
return_status() {
    echo "%(?:$(status_ok):$(status_err))"
}

# Directory display
mini_dir() {
    if [[ $PWD == $HOME ]]; then
        # If at HOME, print nothing
        echo -n ""
    else
        # If not at HOME, print directory AND a trailing space
        echo -n "%F{blue}%~%f "
    fi
}

# Prompt indicator
prompt_indicator() {
    echo ">"
}

# PROMPT
# Logic: Status + Space + (Dir + Space if exists) + Indicator + Space
PROMPT='$(return_status) $(mini_dir)$(prompt_indicator) '
RPROMPT=''
