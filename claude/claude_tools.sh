# Helper to show available MR tools
mr_help() {
    echo "🔧 Available MR Tools:"
    echo "  getDiff        - Get formatted diff for Claude analysis"
    echo "  update_mr '<summary>' - Update current branch's MR with summary"
    echo ""
    echo "📋 Typical workflow:"
    echo "  1. getDiff"
    echo "  2. Ask Claude to analyze and create summary"
    echo "  3. update_mr '<claude-generated-summary>'"
}

# MR Management Functions for Claude workflow

getDiff() {
    # Check if we're in a git repository
    if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    # Check if we're on master/main
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "master" || "$current_branch" == "main" ]]; then
        echo "❌ Currently on $current_branch branch. Switch to feature branch first."
        return 1
    fi
    
    # Get comprehensive diff info optimized for Claude
    echo "## Branch: $current_branch"
    echo ""
    
    echo "### Files Changed:"
    git diff master...HEAD --name-status | head -20
    echo ""
    
    echo "### Commit Messages:"
    git log master..HEAD --oneline | head -10
    echo ""
    
    echo "### Diff Stats:"
    git diff master...HEAD --stat | head -15
    echo ""
    
    echo "### Key Code Changes:"
    git diff master...HEAD --no-merges --unified=2 | head -50
}


  update_mr() {
    local summary="$1"
    
    if [[ -z "$summary" ]]; then
        echo "❌ Usage: update_mr '<summary of changes>'"
        echo "💡 Tip: Run getDiff first, then call this with Claude's summary"
        return 1
    fi
    
    # Verify we're in a git repository
    if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    local current_branch=$(git branch --show-current)
    echo "🔍 Looking for MR for branch: $current_branch"
    
    # Get MR list and parse with awk
    local mr_output=$(glab mr list --source-branch="$current_branch" 2>/dev/null)
    
    if [[ -z "$mr_output" ]] || [[ "$mr_output" == *"No open merge requests"* ]]; then
        echo "❌ No open MR found for branch '$current_branch'"
        echo "💡 Create MR first: glab mr create"
        return 1
    fi
    
    # Extract MR ID using awk (more reliable than grep/sed)
    local mr_id=$(echo "$mr_output" | awk '/^!/ {gsub(/!/, "", $1); print $1; exit}')
    
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

# Get Jira ticket details from branch name or explicit ticket ID
get_jira_ticket() {
    local ticket_id="$1"
    
    # If no ticket provided, extract from current branch name
    if [[ -z "$ticket_id" ]]; then
        # Check if we're in a git repository
        if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
            echo "❌ Not in a git repository and no ticket ID provided"
            echo "💡 Usage: get_jira_ticket [TICKET-ID]"
            return 1
        fi
        
        local current_branch=$(git branch --show-current)
        echo "🔍 Extracting ticket ID from branch: $current_branch"
        
        # Extract ticket ID using awk
        ticket_id=$(echo "$current_branch" | awk -F'/' '{
            for(i=1; i<=NF; i++) {
                if(match($i, /^[A-Z][A-Z]+-[0-9]+/)) {
                    print substr($i, RSTART, RLENGTH)
                    exit
                }
            }
        }')
        
        # Fallback for ME- tickets specifically
        if [[ -z "$ticket_id" ]]; then
            case "$current_branch" in
                *ME-[0-9]*) ticket_id=$(echo "$current_branch" | sed 's/.*\(ME-[0-9]\+\).*/\1/') ;;
                *) ticket_id="" ;;
            esac
        fi
        
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
    
    # Get comprehensive ticket details with all important fields
    if acli jira workitem view "$ticket_id" --fields '*all' --json > /tmp/jira_${ticket_id}.json 2>/dev/null; then
        
        # Parse and display key information from JSON
        local jira_data="/tmp/jira_${ticket_id}.json"
        
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
        if [[ -n "$parent" ]]; then
            echo "Parent: $parent"
        fi
        
        local epic=$(jq -r '.fields.customfield_10014 // empty' "$jira_data")
        if [[ -n "$epic" && "$epic" != "null" ]]; then
            echo "Epic: $epic"
        fi
        
        # Sprint and Team
        local sprint=$(jq -r '.fields.customfield_10020[0].name // empty' "$jira_data" 2>/dev/null)
        if [[ -n "$sprint" && "$sprint" != "null" ]]; then
            echo "Sprint: $sprint"
        fi
        
        local team=$(jq -r '.fields.customfield_10067.value // empty' "$jira_data")
        if [[ -n "$team" && "$team" != "null" ]]; then
            echo "Team: $team"
        fi
        
        echo ""
        echo "📝 DESCRIPTION"
        echo "=============="
        jq -r '.fields.description // "No description"' "$jira_data"
        
        echo ""
        echo "✅ ACCEPTANCE CRITERIA"
        echo "====================="
        local acceptance=$(jq -r '.fields.customfield_10068 // empty' "$jira_data")
        if [[ -n "$acceptance" && "$acceptance" != "null" ]]; then
            echo "$acceptance"
        else
            echo "No acceptance criteria defined"
        fi
        
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
        
        # Clean up temp file
        rm -f "$jira_data"
        return 0
    else
        echo "❌ Failed to fetch ticket details for $ticket_id"
        echo "💡 Make sure:"
        echo "   - You're authenticated: acli auth login"
        echo "   - Ticket ID is correct: $ticket_id" 
        echo "   - You have access to this Jira instance"
        return 1
    fi
}


echo "🔧 MR tools loaded: getDiff, update_mr, mr_help"