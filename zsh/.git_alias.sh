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

# ----------------------
# Worktree management
# ----------------------

function wtadd() {
  local WT_ROOT=~/work/mercanis/worktrees
  local BRANCH="$1"

  if [[ -z "$BRANCH" ]]; then
    read "BRANCH?Nombre de la rama: "
    [[ -z "$BRANCH" ]] && return 1
  fi

  local REPO
  REPO=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$REPO" ]]; then
    echo "No estás dentro de un repo Git"
    return 1
  fi

  cd "$REPO" || return 1

  local DEFAULT_BRANCH
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  if [[ -z "$DEFAULT_BRANCH" ]]; then
    echo "No se pudo detectar la rama por defecto (¿hay un remote llamado origin?)"
    return 1
  fi

  if ! git show-ref --quiet refs/heads/"$BRANCH"; then
    git fetch origin "$DEFAULT_BRANCH"
    git branch "$BRANCH" origin/"$DEFAULT_BRANCH"
  fi

  git worktree add "$WT_ROOT/$BRANCH" "$BRANCH"
}

export WT_PREV_DIR=""

function wtls() {
  local WT_ROOT=~/work/mercanis/worktrees
  local CHOICE

  CHOICE=$(find "$WT_ROOT" -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Worktrees > " --height=40%)

  if [[ -n "$CHOICE" ]]; then
    export WT_PREV_DIR="$PWD"
    cd "$CHOICE"
  fi
}

function wtback() {
  if [[ -n "$WT_PREV_DIR" && -d "$WT_PREV_DIR" ]]; then
    cd "$WT_PREV_DIR"
    WT_PREV_DIR=""
  else
    echo "No hay un directorio anterior guardado"
  fi
}

function wtre() {
  local WT_ROOT=~/work/mercanis/worktrees
  local CHOICE

  CHOICE=$(find "$WT_ROOT" -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Borrar worktree > " --height=40%)

  if [[ -n "$CHOICE" ]]; then
    git -C "$CHOICE" worktree remove "$CHOICE"
  fi
}

function wtmove() {
  local WT_ROOT=~/work/mercanis/worktrees
  local TARGET_BRANCH="$1"

  if [[ -z "$TARGET_BRANCH" ]]; then
    TARGET_BRANCH=$(find "$WT_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="Mover cambios a > ")
    [[ -z "$TARGET_BRANCH" ]] && return 1
  fi

  local REPO
  REPO=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "No estás dentro de un repo Git"
    return 1
  }

  cd "$REPO" || return 1

  if [[ -z $(git status --porcelain) ]]; then
    echo "No hay cambios para mover"
    return 0
  fi

  git stash push -u -k -m "wtmove: $TARGET_BRANCH"
  git stash push -m "wtmove-stage: $TARGET_BRANCH"

  local DEST="$WT_ROOT/$TARGET_BRANCH"
  if [[ ! -d "$DEST" ]]; then
    echo "El worktree '$TARGET_BRANCH' no existe en $WT_ROOT"
    return 1
  fi

  cd "$DEST" || return 1

  git stash pop
  git stash pop
}

# ----------------------
# Git Merge Request
# ----------------------

cmr() {
  local target_branch="${1:-master}"
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local encoded_branch=$(echo "$branch" | sed 's/\//%2F/g')
  local encoded_target=$(echo "$target_branch" | sed 's/\//%2F/g')
  local base_url="https://gitlab.com/cdc3-dev/frontend/frontend-monorepo/-/merge_requests/new"
  local url="$base_url?merge_request%5Bsource_branch%5D=$encoded_branch&merge_request%5Btarget_branch%5D=$encoded_target"

  echo "🔗 Merge request URL:"
  echo "$url"
  echo "🚀 Opening in the browser..."
  open "$url" 2>/dev/null || echo "👉 Copy and paste this URL in your browser"
}