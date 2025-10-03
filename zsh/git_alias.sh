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
#
# This function lists Git branches (local by default, or all with `-a`) in an interactive fzf menu.
# - Left pane: Displays branches for selection (local or all, depending on the argument).
# - Right pane: Dynamically shows the Git commit graph and logs for the branch currently highlighted.
# Selecting a branch with Enter will check it out.
# Exiting with ESC will leave the current branch unchanged.
#
# Usage:
#   branch        # Show local branches
#   branch -a     # Show all branches (local + remote)

function branch() {
  local branches
  if [[ "$1" == "-a" ]]; then
    branches=(${(f)"$(git branch -a --color=always)"})
  else
    branches=(${(f)"$(git branch --color=always)"})
  fi

  local selected=$(printf "%s\n" "${branches[@]}" | \
    fzf --height 100% --border --ansi --tac --preview-window right:50% \
      --preview '
        branch_name=$(echo {} | sed "s/^..//");
        echo -e "\033[1;36mBranch:\033[0m \033[33m$branch_name\033[0m";
        git log --color=always --oneline --graph --date=short \
          --pretty=format:"%C(bold blue)%cd %C(auto)%h%C(bold yellow)%d %C(reset)%s" $branch_name 2>/dev/null
      ' \
  | sed 's/^..//')

  if [[ -n "$selected" ]]; then
    git checkout "$selected"
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

# Rename current branch to the specified name
function rename() {
    local new_name="$1"
    
    if [[ -z "$new_name" ]]; then
        echo "Error: Please provide a new branch name."
        echo "Usage: rename <new-branch-name>"
        return 1
    fi
    
    # Get current branch name
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    
    if [[ -z "$current_branch" ]]; then
        echo "Error: Not on any branch (detached HEAD state)."
        return 1
    fi
    
    # Check if new branch name already exists
    if git show-ref --verify --quiet refs/heads/"$new_name"; then
        echo "Error: Branch '$new_name' already exists."
        return 1
    fi
    
    # Rename the branch
    git branch -m "$current_branch" "$new_name"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Branch renamed from '$current_branch' to '$new_name'"
        
        # Check if the old branch had an upstream
        local upstream
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
        
        if [[ -n "$upstream" ]]; then
            echo "📡 Updating upstream reference..."
            git push origin :"$current_branch" 2>/dev/null || true  # Delete old remote branch (ignore if it fails)
            git push --set-upstream origin "$new_name"  # Push new branch with upstream
        fi
    else
        echo "❌ Failed to rename branch."
        return 1
    fi
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

# ----------------------
# Git Squash
# ----------------------

squash() {
  target_branch="$1"

  if [ -z "$target_branch" ]; then
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    target_branch="origin/$current_branch"
  fi

  git merge --squash "$target_branch"
}


# WORKTREES

# Create a worktree for code review
worktree() {
    if [[ -z "$1" ]]; then
        echo "Usage: worktree <branch-name>"
        echo "Creates a worktree at ~/work/mercanis/worktrees/<branch-name>"
        return 1
    fi
    
    local branch_name="$1"
    local worktree_dir="$HOME/work/mercanis/worktrees/$branch_name"
    
    # Create the worktrees directory if it doesn't exist
    mkdir -p "$HOME/work/mercanis/worktrees"
    
    # Check if worktree already exists
    if [[ -d "$worktree_dir" ]]; then
        echo "Worktree already exists at: $worktree_dir"
        echo "Use 'dump_worktree $branch_name' to remove it first"
        return 1
    fi
    
    # Create the worktree
    if git worktree add "$worktree_dir" "$branch_name"; then
        echo "✅ Worktree created successfully!"
        echo "📁 Location: $worktree_dir"
        echo "🚀 Run: cd $worktree_dir"
    else
        echo "❌ Failed to create worktree"
        return 1
    fi
}

# Remove a worktree
dump_worktree() {
    if [[ -z "$1" ]]; then
        echo "Usage: dump_worktree <branch-name>"
        echo "Removes the worktree at ~/work/mercanis/worktrees/<branch-name>"
        return 1
    fi
    
    local branch_name="$1"
    local worktree_dir="$HOME/work/mercanis/worktrees/$branch_name"
    
    # Check if worktree exists
    if [[ ! -d "$worktree_dir" ]]; then
        echo "❌ Worktree not found at: $worktree_dir"
        return 1
    fi
    
    # Remove the worktree
    if git worktree remove "$worktree_dir"; then
        echo "✅ Worktree removed successfully!"
        echo "🗑️  Removed: $worktree_dir"
    else
        echo "❌ Failed to remove worktree"
        echo "💡 Try: git worktree remove --force $worktree_dir"
        return 1
    fi
}

# Remove all worktrees in the mercanis directory
prune_worktrees() {
    local worktrees_base="$HOME/work/mercanis/worktrees"
    
    if [[ ! -d "$worktrees_base" ]]; then
        echo "📁 No worktrees directory found at: $worktrees_base"
        return 0
    fi
    
    # Get list of worktrees in our specific directory
    local worktrees_to_remove=()
    
    # Parse git worktree list output with awk
    while IFS= read -r worktree_path; do
        if [[ -n "$worktree_path" && "$worktree_path" == "$worktrees_base"/* ]]; then
            worktrees_to_remove+=("$worktree_path")
        fi
    done < <(git worktree list | awk '{print $1}')
    
    if [[ ${#worktrees_to_remove[@]} -eq 0 ]]; then
        echo "✨ No worktrees found in $worktrees_base"
        return 0
    fi
    
    echo "🗑️  Found ${#worktrees_to_remove[@]} worktree(s) to remove:"
    for wt in "${worktrees_to_remove[@]}"; do
        echo "   - $wt"
    done
    
    echo -n "❓ Remove all these worktrees? [y/N]: "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        local removed_count=0
        local failed_count=0
        
        for wt in "${worktrees_to_remove[@]}"; do
            if git worktree remove "$wt" 2>/dev/null; then
                echo "✅ Removed: $wt"
                ((removed_count++))
            else
                echo "❌ Failed to remove: $wt"
                ((failed_count++))
            fi
        done
        
        echo "🎉 Summary: $removed_count removed, $failed_count failed"
        
        # Clean up empty directory if all were removed successfully
        if [[ $failed_count -eq 0 && -d "$worktrees_base" ]]; then
            rmdir "$worktrees_base" 2>/dev/null && echo "🧹 Cleaned up empty worktrees directory"
        fi
    else
        echo "🚫 Operation cancelled"
    fi
}

# List all worktrees
list_worktrees() {
    echo "📋 Current worktrees:"
    git worktree list
}