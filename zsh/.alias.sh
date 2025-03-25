# Aliases
alias code="windsurf"
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
# Git Aliases and Functions
# ----------------------

# Self-explanatory Git aliases
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

# Interactive Git branch deletion
alias delete_branches="git branch --no-color | fzf -m | xargs -I {} git branch -D '{}'"

# Copy current branch name to clipboard
function cpbn() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)

    if [ -n "$current_branch" ]; then
        echo "$current_branch" | pbcopy && echo "Copied branch name to clipboard: $current_branch"
    else
        echo "Not on any branch."
    fi
}

# Push with upstream tracking
function gpsup() {
    branch_name=$(git rev-parse --abbrev-ref HEAD)
    if [ "$branch_name" = "HEAD" ]; then
        echo "Error: Detached HEAD state. Please checkout a branch first."
        return 1
    fi
    git push --set-upstream origin "$branch_name"
}

# Extract commit hashes between branches
function extract_commits() {
    local target_branch="$1" base_branch="$2"
    if [[ -z "$target_branch" || -z "$base_branch" ]]; then
        echo "Error: Both target and base branches must be provided."
        return 1
    fi

    if ! git rev-parse --quiet --verify "$target_branch" || ! git rev-parse --quiet --verify "$base_branch"; then
        echo "Invalid branch names provided."
        return 1
    fi

    commits=$(git cherry -v "$target_branch" "$base_branch" |
              tr -s '[:blank:]' | cut -f 2 -d ' ' | cut -c 1-10 | tr '\n' ' ')
    if [[ -z "$commits" ]]; then
        echo "No new commits found for cherry-pick."
        return 1
    fi

    echo -n "$commits" | pbcopy
    echo "Copied new commits for cherry-pick: $commits"
}

# Interactive Git branch switching with fzf
# This function lists local Git branches in an interactive fzf menu.
# - Left pane: Displays all local branches for selection.
# - Right pane: Dynamically shows the Git commit graph and logs for the branch currently highlighted.
# Selecting a branch with Enter will check it out.
# Exiting with ESC will leave the current branch unchanged.
function branch() {
    local fzf_command="
        fzf --height 100% --border --ansi --tac --preview-window right:50% \
        --preview '
            branch_name=\$(echo {} | sed \"s/^..//\");
            echo -e \"\\e[1;36mBranch:\\e[0m \\e[33m\$branch_name\\e[0m\";
            git log --color=always --oneline --graph --date=short \
            --pretty=format:\"%C(bold blue)%cd %C(auto)%h%C(bold yellow)%d %C(reset)%s\" \$branch_name 2>/dev/null
        '
    "
    local result=$(git branch --color=always | eval "$fzf_command" | sed 's/^..//')
    if [[ -n "$result" ]]; then
        git checkout "$result"
    fi
}

# Git log selector with fzf
function log() {
    git log \
        --color=always \
        --pretty=format:'%C(auto)%h %Cgreen%ad%Creset %C(yellow)%d %C(white)%s %C(magenta)[%cn]%Creset' \
        --decorate --date=short | \
    fzf --ansi --reverse --multi \
        --preview='echo {} | cut -d" " -f1 | xargs git show --color=always' \
        --preview-window='right:60%:wrap' | \
    awk '{print $1}' | tr "\n" " " | pbcopy
}

# Git worktree
function gwta() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: git-worktree-add <folder-name> [branch-name]"
    return 1
  fi

  local folder_name=$1
  local branch_name=$2

  # If no branch name is provided, use the current branch
  if [[ -z $branch_name ]]; then
    branch_name=$(git symbolic-ref --short HEAD)
    echo "Using current branch: $branch_name"
  fi

  git worktree add ~/work/mercanis/worktrees/$folder_name $branch_name
}

function gwtl() {
  # Create worktrees directory if it doesn't exist
  mkdir -p ~/work/mercanis/worktrees

  case "$1" in
    add)
      if [[ $# -lt 2 ]]; then
        echo "Usage: git-worktree add <folder-name> [branch-name]"
        return 1
      fi

      local folder_name=$2
      local branch_name=$3

      # If no branch name is provided, use the current branch
      if [[ -z $branch_name ]]; then
        branch_name=$(git symbolic-ref --short HEAD)
        echo "Using current branch: $branch_name"
      fi

      git worktree add ~/work/mercanis/worktrees/$folder_name $branch_name
      ;;

    remove)
      if [[ $# -eq 2 ]]; then
        local folder_name=$2
        local worktree_path=~/work/mercanis/worktrees/$folder_name

        if [[ ! -d $worktree_path ]]; then
          echo "Worktree not found: $worktree_path"
          return 1
        fi

        git worktree remove $worktree_path
        echo "Removed worktree: $worktree_path"
      else
        # Use fzf to select a worktree to remove
        local selected=$(find ~/work/mercanis/worktrees -maxdepth 1 -mindepth 1 -type d | sort | fzf --height 40% --reverse --prompt="Select worktree to remove: ")

        if [[ -n $selected ]]; then
          git worktree remove $selected
          echo "Removed worktree: $selected"
        fi
      fi
      ;;

    list)
      echo "Worktrees:"
      git worktree list
      ;;

    goto)
      if [[ $# -eq 2 ]]; then
        local folder_name=$2
        local worktree_path=~/work/mercanis/worktrees/$folder_name

        if [[ ! -d $worktree_path ]]; then
          echo "Worktree not found: $worktree_path"
          return 1
        fi

        cd $worktree_path
        echo "Switched to worktree: $worktree_path"
      else
        # Use fzf to select a worktree to go to
        local selected=$(find ~/work/mercanis/worktrees -maxdepth 1 -mindepth 1 -type d | sort | fzf --height 40% --reverse --prompt="Select worktree to go to: ")

        if [[ -n $selected ]]; then
          cd $selected
          echo "Switched to worktree: $selected"
        fi
      fi
      ;;

    *)
      echo "Usage: git-worktree <command>"
      echo "Commands:"
      echo "  add <folder-name> [branch-name]  - Create a new worktree"
      echo "  remove [folder-name]             - Remove a worktree (interactive if no name provided)"
      echo "  list                             - List all worktrees"
      echo "  goto [folder-name]               - Go to a worktree (interactive if no name provided)"
      ;;
  esac
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

# VISET
## Load keys
fetch_signing_passwords() {
    OP_ID="me6mzbdnlp4qhizlrk6utzzm3q"

    export SIGNING_STORE_PASSWORD=$(op item get "$OP_ID" --field password --reveal)
    export SIGNING_KEY_PASSWORD=$(op item get "$OP_ID" --field password --reveal)

    echo "Passwords set ✅"
}
