export ZPLUG_HOME=$HOMEBREW_PREFIX/opt/zplug
    source $ZPLUG_HOME/init.zsh

zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"
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

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
# Use java 21
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH

# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# My aliases
source ~/.alias.sh

# Starship https://starship.rs/
eval "$(starship init zsh)"
# Added by Windsurf
export PATH="/Users/uciel/.codeium/windsurf/bin:$PATH"

# Created by `pipx` on 2025-03-14 19:19:00
export PATH="$PATH:/Users/uciel/.local/bin"
