#
# getDiff - Generate diff summary for Claude analysis
#
# Usage: getDiff [base_branch]
# Default base_branch: master
#
# Analyzes changes between feature branch and base branch.
# Must be run on feature branch from git repository.
#
# The code changes section uses `head -200` to limit token consumption
# while preserving critical information. Adjust based on change size:
# - Small changes: head -100 (faster Claude processing)
# - Large refactors: head -500 or remove entirely
# - Very large: remove head limit and review in sections
#
# Output: branch name, changed files, commits, stats, code diff
# Exit: 0=success, 1=error
#
getDiff() {
    local base_branch="${1:-master}"
    
    # Validate git repository
    if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    # Get current branch and check not on base branch
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "$base_branch" ]]; then
        echo "❌ Currently on $current_branch branch. Switch to feature branch first."
        return 1
    fi
    
    # Generate structured output
    echo "## Branch: $current_branch (comparing to $base_branch)"
    echo ""
    
    echo "### Files Changed:"
    git diff "$base_branch"...HEAD --name-status
    echo ""
    
    echo "### Commit Messages:"
    git log "$base_branch"..HEAD --oneline
    echo ""
    
    echo "### Diff Stats:"
    git diff "$base_branch"...HEAD --stat
    echo ""
    
    echo "### Key Code Changes:"
    git diff "$base_branch"...HEAD --no-merges --unified=3 | head -200
}

#
# update_mr - Update GitLab MR description with summary
#
# Usage: update_mr '<summary of changes>'
#
# Updates the description of an open MR for current branch.
# Requires glab CLI and existing MR for current branch.
#
# Exit: 0=success, 1=error
#
update_mr() {
      local summary="$1"

      # Validate required summary parameter
      if [[ -z "$summary" ]]; then
          echo "❌ Usage: update_mr '<summary of changes>'"
          echo "💡 Tip: Run getDiff first, then call this with Claude's summary"
          return 1
      fi

      # Validate git repository
      if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
          echo "❌ Not in a git repository"
          return 1
      fi

      local current_branch=$(git branch --show-current)
      echo "🔍 Looking for MR for branch: $current_branch"

      # Find MR for current branch using JSON output for reliable parsing
      local mr_output=$(glab mr list --source-branch="$current_branch" --output json 2>/dev/null)

      if [[ -z "$mr_output" ]] || [[ "$mr_output" == "[]" ]]; then
          echo "❌ No open MR found for branch '$current_branch'"
          echo "💡 Create MR first: glab mr create"
          return 1
      fi

      # Extract MR ID from JSON
      local mr_id=$(echo "$mr_output" | jq -r '.[0].iid // empty' 2>/dev/null)

      if [[ -z "$mr_id" ]]; then
          echo "❌ Could not extract MR ID from glab output"
          echo "🐛 Debug output:"
          echo "$mr_output"
          return 1
      fi

      echo "📝 Found MR !$mr_id"
      echo "🔄 Updating description..."

      # Update MR description
      if glab mr update "$mr_id" --description "$summary" 2>/dev/null; then
          echo "✅ Successfully updated MR !$mr_id"
          echo "🔗 View: glab mr view $mr_id --web"
      else
          echo "❌ Failed to update MR description"
          return 1
      fi
}


#
# get_jira_ticket - Fetch comprehensive Jira ticket details
#
# Usage: get_jira_ticket [TICKET-ID]
# If no TICKET-ID provided, extracts from current git branch name
#
# Requires: acli, jq, git (if auto-extracting)
# Exit: 0=success, 1=error
#
get_jira_ticket() {
    local ticket_id="$1"
    
    # Auto-extract ticket ID from branch name if not provided
    if [[ -z "$ticket_id" ]]; then
        if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
            echo "❌ Not in a git repository and no ticket ID provided"
            echo "💡 Usage: get_jira_ticket [TICKET-ID]"
            return 1
        fi
        
        local current_branch=$(git branch --show-current)
        echo "🔍 Extracting ticket ID from branch: $current_branch"
        
        # Extract ME-123 format from branch name
        ticket_id=$(echo "$current_branch" | grep -o 'ME-[0-9]\+' | head -1)
        
        if [[ -z "$ticket_id" ]]; then
            echo "❌ No Jira ticket ID found in branch name: $current_branch"
            echo "💡 Branch should contain format like 'ME-123'"
            echo "💡 Or provide ticket ID explicitly: get_jira_ticket ME-123"
            return 1
        fi
        
        echo "🎫 Found ticket ID: $ticket_id"
    fi
    
    echo "📋 Fetching comprehensive Jira ticket details for: $ticket_id"
    echo ""
    
    # Fetch ticket data using acli
    local jira_data="/tmp/jira_${ticket_id}.json"
    if ! acli jira workitem view "$ticket_id" --fields '*all' --json > "$jira_data" 2>/dev/null; then
        echo "❌ Failed to fetch ticket details for $ticket_id"
        echo "💡 Make sure:"
        echo "   - You're authenticated: acli auth login"
        echo "   - Ticket ID is correct: $ticket_id" 
        echo "   - You have access to this Jira instance"
        return 1
    fi
    
    # Display ticket overview
    echo "🎯 TICKET OVERVIEW"
    echo "=================="
    echo "Key: $(jq -r '.key // "N/A"' "$jira_data")"
    echo "Summary: $(jq -r '.fields.summary // "N/A"' "$jira_data")"
    echo "Type: $(jq -r '.fields.issuetype.name // "N/A"' "$jira_data")"
    echo "Status: $(jq -r '.fields.status.name // "N/A"' "$jira_data")"
    echo "Priority: $(jq -r '.fields.priority.name // "N/A"' "$jira_data")"
    echo "Assignee: $(jq -r '.fields.assignee.displayName // "Unassigned"' "$jira_data")"
    
    # Parent/Epic information
    local parent=$(jq -r '.fields.parent.key // empty' "$jira_data")
    [[ -n "$parent" ]] && echo "Parent: $parent"
    
    local epic=$(jq -r '.fields.customfield_10014 // empty' "$jira_data")
    [[ -n "$epic" && "$epic" != "null" ]] && echo "Epic: $epic"
    
    # Sprint and Team
    local sprint=$(jq -r '.fields.customfield_10020[0].name // empty' "$jira_data" 2>/dev/null)
    [[ -n "$sprint" && "$sprint" != "null" ]] && echo "Sprint: $sprint"
    
    local team=$(jq -r '.fields.customfield_10067.value // empty' "$jira_data")
    [[ -n "$team" && "$team" != "null" ]] && echo "Team: $team"
    
    # Description
    echo ""
    echo "📝 DESCRIPTION"
    echo "=============="
    jq -r '.fields.description // "No description"' "$jira_data"
    
    # Acceptance Criteria
    echo ""
    echo "✅ ACCEPTANCE CRITERIA"
    echo "====================="
    local acceptance=$(jq -r '.fields.customfield_10068 // empty' "$jira_data")
    if [[ -n "$acceptance" && "$acceptance" != "null" ]]; then
        echo "$acceptance"
    else
        echo "No acceptance criteria defined"
    fi
    
    # Notes
    echo ""
    echo "📋 NOTES"
    echo "========"
    local notes=$(jq -r '.fields.customfield_10069 // empty' "$jira_data")
    if [[ -n "$notes" && "$notes" != "null" ]]; then
        echo "$notes"
    else
        echo "No additional notes"
    fi
    
    # Subtasks
    local subtasks=$(jq -r '.fields.subtasks[]?.key // empty' "$jira_data" 2>/dev/null)
    if [[ -n "$subtasks" ]]; then
        echo ""
        echo "🔗 SUBTASKS"
        echo "==========="
        echo "$subtasks"
    fi
    
    echo ""
    echo "🔗 URL: https://mercanis.atlassian.net/browse/$ticket_id"
    echo ""
    echo "✅ Comprehensive ticket details retrieved successfully"
    
    # Cleanup
    rm -f "$jira_data"
}