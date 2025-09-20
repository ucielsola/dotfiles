# Aliases
alias zshcfg="code ~/dotfiles/zsh/.zshrc"
alias aliascfg="code ~/dotfiles/zsh/.alias.sh"
alias src="source ~/.zshrc"
alias c="clear"
alias prd="pnpm run dev"
alias lg="lazygit"

# ----------------------
# LSD (better ls)
# ----------------------
alias ls="lsd -A --group-dirs first --date relative --size short"

# ----------------------
# Zoxide (better cd)
# ----------------------
alias cd="z"
alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."

# Enhanced interactive directory jumping
function cdi() {
    local selected_dir
    selected_dir=$(zoxide query -l | \
        fzf --reverse \
            --height=50% \
            --border=rounded \
            --prompt="🔍 " \
            --pointer="➜" \
            --header="Jump to directory" \
            --preview='lsd -l --color=always {}' \
            --preview-window='right:60%:wrap' \
            --bind='ctrl-/:toggle-preview')

    [[ -n "$selected_dir" ]] && z "$selected_dir"
}

# ----------------------
# System and Utilities
# ----------------------
alias ip="ipconfig getifaddr en0"  # Get local IP
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"  # Flush DNS
alias ports="lsof -PiTCP -sTCP:LISTEN"  # Show listening ports
alias cpwd="pwd | pbcopy"  # Copy current path
alias rmf="rm -rf"  # Force remove
alias sz="du -sh"  # Get size of file/directory

alias mv="mv -i"  # Prompt before overwrite
alias cp="cp -i"  # Prompt before overwrite
alias rm="rm -i"  # Prompt before delete
alias grep="rg --color=auto --line-number --smart-case"

# Directory size overview with exclusions
function sizes() {
    local path="${1:-.}"
    echo "Scanning directory: $path (excluding .git and node_modules)"
    ncdu -rr -x --exclude .git --exclude node_modules "$path"
}

# Quick mkdir + cd
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Brew maintenance with outdated check
function bru() {
    echo "📦 Checking outdated packages..."
    outdated=$(brew outdated)

    if [ -z "$outdated" ]; then
        echo "✨ All packages are up to date!"
        return
    fi

    echo "$outdated"
    echo -n "Continue with update? [y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if brew update; then
            brew upgrade && brew cleanup
            echo "✨ Brew update complete!"
        else
            echo "❌ Brew update failed. Aborting upgrade."
        fi
    else
        echo "🚫 Update canceled."
    fi
}

# YouTube audio downloader
function yt() {
    local url="$1"

    if [[ -z "$url" ]]; then
        echo "❌ Usage: yt <youtube-url>"
        echo "💡 Example: yt 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
        return 1
    fi

    echo "🎵 Downloading audio from: $url"
    yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata --add-metadata -o "~/Downloads/%(title)s.%(ext)s" "$url"
}