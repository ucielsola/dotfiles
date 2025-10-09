# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export ZPLUG_HOME=$HOMEBREW_PREFIX/opt/zplug
    source $ZPLUG_HOME/init.zsh

zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'

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
source ~/alias.sh
source ~/git_alias.sh


#PNPM
export PATH="/opt/homebrew/opt/pnpm@8/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Load Angular CLI autocompletion.
source <(ng completion script)

# Load secrets
source ~/.secrets

# Set environment variables from 1Password
function set_env() {
    # GitLab token from Mercanis account (Tech vault)
    GL_TOKEN_ID="mc62dpxoklkkwt3qybp5dttpbe"
    export GL_TOKEN=$(op read "op://Tech/$GL_TOKEN_ID/credential" --account "mercanis.1password.com")
}

export EDITOR=code
