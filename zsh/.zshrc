export ZPLUG_HOME=$HOMEBREW_PREFIX/opt/zplug
    source $ZPLUG_HOME/init.zsh

zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"

# For fzf-tab completion (highly recommended)
zplug "Aloxaf/fzf-tab"

zplug load


# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"
eval $(thefuck --alias)

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward


# Node Version Manager
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# Open JDK
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"

# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# My aliases
source ~/.alias.sh
source ~/.git_alias.sh
source ~/claude_tools.sh

# Starship https://starship.rs/
eval "$(starship init zsh)"
# Added by Windsurf
export PATH="/Users/uciel/.codeium/windsurf/bin:$PATH"

# Created by `pipx` on 2025-03-14 19:19:00
export PATH="$PATH:/Users/uciel/.local/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/uciel/.lmstudio/bin"

#PNPM
export PATH="/opt/homebrew/opt/pnpm@8/bin:$PATH"

# Load Angular CLI autocompletion.
source <(ng completion script)

# Added by Windsurf
export PATH="/Users/uciel/.codeium/windsurf/bin:$PATH"

# Set environment variables from 1Password
function set_env() {
    GL_TOKEN_ID="mc62dpxoklkkwt3qybp5dttpbe"
    export GL_TOKEN=$(op read "op://Tech/$GL_TOKEN_ID/credential")
}

source /Users/uciel/dotfiles/review/main.sh
    export PATH="$HOME/.local/bin:$PATH"

# Poetry Auto-Fix Function
# Use this instead of 'just install' to automatically handle Poetry issues
poetry-install() {
    local project_root=$(pwd)
    if [[ -f "$project_root/fix-poetry.sh" ]]; then
        "$project_root/fix-poetry.sh"
    elif [[ -f "$project_root/../fix-poetry.sh" ]]; then
        "$project_root/../fix-poetry.sh"
    else
        echo "fix-poetry.sh not found. Running regular just install..."
        just install
    fi
}

# Alias for convenience
alias pi="poetry-install"
