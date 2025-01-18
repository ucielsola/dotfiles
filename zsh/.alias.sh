# Aliases
alias zshcfg="code ~/dotfiles/zsh/.zshrc"
alias aliascfg="code ~/dotfiles/zsh/.alias.sh"
alias src="source ~/.zshrc"
alias c="clear"
alias prd="pnpm run dev"
alias lg="lazygit"
alias esp="code ~/Library/Application\ Support/espanso/match/base.yml"

# ---- LSD (better ls) -----
alias ls="lsd -A --group-dirs first --date relative --size short"
# ---- Zoxide (better cd) ----
alias cd="z"

### GIT ALIASES

# Delete branches interactively using fzf
# press TAB to mark the branch(es) to delete, then press ENTER to delete them
# Type branch name to filter between the branches list
# Requires fzf
alias delete_branches="git branch --no-color | fzf -m | xargs -I {} git branch -D '{}'"

# Self-explanatory aliases...
alias ghrm="git reset --hard origin/master"
alias gs="git status -sb"  # Short status with branch info
alias gsw="git switch"
alias gswm="gsw master"
alias gswd="gsw develop"
alias gcb="git checkout -b"
alias ga="git add"
alias gc="git commit"
alias gcp="git cherry-pick"
alias gcpc="git cherry-pick --continue"
alias gcpa="git cherry-pick --abort"

### FUNCTIONS
# cpbn - Copy the current Git branch name to the clipboard.
#
# Dependencies:
#   - Git
#   - Clipboard tool: Uses pbcopy on macOS by default. For Linux, xclip or xsel is recommended.
function cpbn() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)

    if [ -n "$current_branch" ]; then
        echo "$current_branch" | pbcopy && echo "Copied branch name to clipboard: $current_branch"
    else
        echo "Not on any branch."
    fi
}


# ...
gpsup() {
    # Get the current branch name
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    # Check if the branch name is valid
    if [ "$branch_name" = "HEAD" ]; then
        echo "Error: You are in a detached HEAD state. Please checkout a branch first."
        return 1
    fi

    # Push with --set-upstream to origin
    git push --set-upstream origin "$branch_name"
}

# extract_commits - Extracts new commit hashes between a target branch and a base branch using git cherry, and copies the resulting commit list to the clipboard
extract_commits() {
    local target_branch="$1" base_branch="$2"

    # Input validation
    if [[ -z "$target_branch" || -z "$base_branch" ]]; then
        echo "Error: Both target and base branches must be provided."
        return 1
    fi

    # Validate branch existence
    if ! git rev-parse --quiet --verify "$target_branch" || ! git rev-parse --quiet --verify "$base_branch"; then
        echo "Invalid branch names provided."
        return 1
    fi

    # Run git cherry, trim excess whitespace, and filter commit hashes
    commits=$(git cherry -v "$target_branch" "$base_branch" |
              tr -s '[:blank:]' | cut -f 2 -d ' ' | cut -c 1-10 | tr '\n' ' ')

    # Verify commit list
    if [[ -z "$commits" ]]; then
        echo "No new commits found for cherry-pick."
        return 1
    fi

    # Copy commits to clipboard and print confirmation
    if command -v pbcopy >/dev/null; then
        echo -n "$commits" | pbcopy
        echo "Copied new commits for cherry-pick: $commits"
    else
        echo "Error: pbcopy command not found. Could not copy to clipboard."
    fi
}


# branch - Interactive Git branch switching using fzf.
#
# Usage:
#   branch               - Lists local branches.
#   branch -a            - Lists both local and remote branches.
#
# This function uses fzf to interactively select a Git branch and switch to it.
# If the selected branch is a remote branch, it sets up tracking and checks it out.
#
# Dependencies:
#   - Git
#   - fzf (https://github.com/junegunn/fzf)
#

function branch() {
    # Pass -a to also list remote branches
    list_all=false

    if [[ $1 == "-a" ]]; then
        list_all=true
        shift
    fi

    # Define a common fzf command for both local and remote branches
    fzf_command="fzf --height 100% --border --ansi --tac --preview-window right:50% \
        --preview 'echo -e \"\e[1mBranch: \$(sed s/^..// <<< {} | cut -d\" \" -f1)\e[0m\"; \
        git log --oneline --graph --date=short --pretty=\"format:%C(auto)%cd %h%d %s\" \$(sed s/^..// <<< {} | cut -d\" \" -f1) | head -$LINES'"

    if $list_all; then
        # List remote branches and use fzf
        result=$(git branch -r --color=always | grep -v '/HEAD\s' | sort | eval "$fzf_command" | sed 's/^..//' | cut -d' ' -f1)
    else
        # List local branches and use fzf
        result=$(git branch --color=always | grep -v '/HEAD\s' | sort | eval "$fzf_command" | sed 's/^..//' | cut -d' ' -f1)
    fi

    # Check if a branch was selected
    if [[ -n "$result" ]]; then
        if [[ $result == remotes/* ]]; then
            # If it's a remote branch, set up tracking and check it out
            git checkout --track "$(echo $result | sed 's#remotes/##')"
        else
            # If it's a local branch, simply check it out
            git checkout "$result"
        fi
    fi
}

#
# log - Git Log FZF Interactive Selector
# Features:
#   - Fuzzy search and filter commits by subject, author, hash, or date.
#   - Live preview of commit details and diffs (uses `git show --color=always`).
#   - Multi-selection support: select multiple commits using TAB.
#   - Automatically copies the selected commit hashes to the clipboard upon exit.
#   - Splits the screen: the left 50% shows the commit list, and the right 50% shows the preview.
#
# Dependencies:
#   - git
#   - fzf (https://github.com/junegunn/fzf)
#   - pbcopy (on macOS for clipboard integration; on Linux, consider xclip or xsel and adjust accordingly)

function log {
    git log \
        --color=always \
        --pretty=format:'%C(auto)%h %Cgreen%ad%Creset %C(yellow)%d %C(white)%s %C(magenta)[%cn]%Creset' \
        --decorate --date=short | \
    fzf --ansi --reverse --multi \
        --preview='echo {} | cut -d" " -f1 | xargs git show --color=always' \
        --preview-window='right:60%:wrap' | \
    awk '{print $1}' | tr "\n" " " | pbcopy
}
# ERU
# activate python env
alias eru_env="source ~/eru/back/venv/bin/activate"

# Quick mkdir + cd
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Brew maintenance with outdated check
function bru() {
    echo "📦 Checking outdated packages..."
    outdated=$(brew outdated)
    
    if [[ -z "$outdated" ]]; then
        echo "✨ All packages are up to date!"
        return
    fi
    
    echo "$outdated"
    echo -n "Continue with update? [y/N] "
    read answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        brew update && brew upgrade && brew cleanup
        echo "✨ Brew update complete!"
    fi
}

# System shortcuts
alias ip="ipconfig getifaddr en0"  # Get local IP
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"  # Flush DNS
alias ports="lsof -PiTCP -sTCP:LISTEN"  # Show listening ports

