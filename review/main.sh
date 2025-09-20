# deps: glab, jq, fzf, ollama
__mr_pick() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Check dependencies
  local _require_cmd() {
    command -v "$1" >/dev/null || { 
      echo "$1 not found" >&2
      return 127
    }
  }
  
  local role args json sel number
  
  _require_cmd glab || return $?
  _require_cmd jq || return $?
  _require_cmd fzf || return $?
  
  # Parse role argument
  role="${1:-assignee}"
  case "$role" in
    assignee) args=(--assignee=@me) ;;
    author)   args=(--author=@me) ;;
    reviewer) args=(--reviewer=@me) ;;
    *)        args=(--assignee=@me) ;;
  esac
  
  # Check if we're in a git repo
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not in a git repository" >&2
    return 1
  fi
  
  # Check GitLab CLI authentication
  if ! glab auth status >/dev/null 2>&1; then
    echo "GitLab CLI not authenticated. Run 'glab auth login'" >&2
    return 1
  fi
  
  # Fetch MR list from GitLab
  json="$(glab mr list "${args[@]}" --per-page 100 --output json 2>/dev/null)"
  
  if [[ $? -ne 0 ]]; then
    echo "Failed to fetch MRs" >&2
    return 1
  fi
  
  # Check for empty results
  if [[ -z "$json" ]] || [[ "$json" = "[]" ]] || [[ "$json" = "null" ]]; then
    echo "No open MRs found for role: $role" >&2
    return 1
  fi
  
  # Parse JSON and format for fzf
  local parsed
  parsed="$(
    printf '%s\n' "$json" | jq -r '.[] | [
      (.iid|tostring),
      (.title|gsub("\n"; " ")|gsub("\t"; " ")),
      (.source_branch // "?"),
      (.updated_at // "")
    ] | @tsv'
  )"
  
  if [[ -z "$parsed" ]]; then
    echo "No MRs to display" >&2
    return 1
  fi
  
  # Show fzf picker with only titles
  sel="$(
    printf '%s\n' "$parsed" | fzf \
          --with-nth=2 \
          --delimiter=$'\t' \
          --prompt='MR > ' \
          --header='Select a Merge Request:' \
          --no-multi
  )" || return $?
  
  # Extract and return MR number
  number="${sel%%$'\t'*}"
  [[ -z "$number" ]] && return 1
  
  printf '%s\n' "$number"
}

__get_mr_diff() {
  local mr_number="$1"
  
  if [[ -z "$mr_number" ]]; then
    echo "MR number required" >&2
    return 1
  fi
  
  echo "Fetching diff for MR #$mr_number..." >&2
  
  glab mr diff "$mr_number" || {
    echo "Failed to fetch MR diff" >&2
    return 1
  }
}

__load_review_rules() {
  local script_dir="${${(%):-%N}:A:h}"
  local rules_file="$script_dir/rules.txt"
  
  if [[ -f "$rules_file" ]]; then
    cat "$rules_file"
  else
    # Default rules if config file doesn't exist
    cat <<'EOF'
Code Review Guidelines:

1. Check for security vulnerabilities and potential exploits
2. Verify proper error handling and edge cases
3. Look for performance issues and inefficient code
4. Ensure code follows consistent style and naming conventions
5. Check for proper documentation and comments where needed
6. Verify that changes don't break existing functionality
7. Look for code duplication and suggest refactoring opportunities
8. Ensure proper testing coverage for new features
9. Check for proper resource cleanup and memory management
10. Verify that the code follows the project's architectural patterns

Focus on constructive feedback with specific suggestions for improvement.
EOF
  fi
}

__ai_code_review() {
  local diff_content="$1"
  
  if [[ -z "$diff_content" ]]; then
    echo "Diff content required" >&2
    return 1
  fi
  
  # Check if ollama is available
  if ! command -v ollama >/dev/null 2>&1; then
    echo "ollama not found" >&2
    return 127
  fi
  
  echo "Running AI code review..." >&2
  
  local rules prompt
  rules="$(__load_review_rules)"
  
  prompt="$(cat <<EOF
Please perform a thorough code review of the following Git diff. Apply these review guidelines:

$rules

Here is the diff to review:

$diff_content

Please provide a structured review with:
1. Summary of changes
2. Issues found (if any)
3. Suggestions for improvement
4. Overall assessment

EOF
)"

  ollama run gpt-oss "$prompt" || {
    echo "Failed to run AI code review" >&2
    return 1
  }
}

mr_review() {
  local number diff_content
  
  echo "Fetching MRs..." >&2
  number="$(__mr_pick "$@")" || {
    local exit_code=$?
    echo "Failed to select MR (exit code: $exit_code)" >&2
    return $exit_code
  }
  
  export MR_NUMBER="$number"
  echo "Selected MR #$MR_NUMBER"
  
  echo "Fetching diff for MR #$number..." >&2
  diff_content="$(glab mr diff "$number")" || {
    echo "Failed to fetch MR diff" >&2
    return 1
  }
  
  __ai_code_review "$diff_content" || return $?
}