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

# AI Tools
source ~/dotfiles/ai/tools.sh

#PNPM
export PATH="/opt/homebrew/opt/pnpm@8/bin:$PATH"

# Load Angular CLI autocompletion.
source <(ng completion script)

# Set environment variables from 1Password
function set_env() {
    GL_TOKEN_ID="mc62dpxoklkkwt3qybp5dttpbe"
    export GL_TOKEN=$(op read "op://Tech/$GL_TOKEN_ID/credential")
}

export EDITOR=code