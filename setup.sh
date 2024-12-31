# Setup
### curl -fsSL https://ucielsola.dev/setup | bash

## List of apps to install manually
### Longshot https://apps.apple.com/cn/app/longshot-screenshot-ocr/id6450262949
### Perplexity https://apps.apple.com/us/app/perplexity-ask-anything/id6714467650



## Brew
### Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### Enable brew
(
  echo
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
) >>/Users/uciel/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

#### Install packages and casks with brew
echo "Updating and upgrading homebrew"
brew update
brew upgrade

#### Create LaunchAgents dir
mkdir -p ~/Library/LaunchAgents

echo "Enabling autoupdate for homebrew packages (every 12 hours)..."
brew tap homebrew/autoupdate
brew autoupdate start 43200 --upgrade

echo "Installing a bunch of apps with Brew"

BREW_APPS=(
  git
  node
  python
  wget
  btop
  nvm
  starship
)

BREW_CASK_APPS=(
  font-caskaydia-mono-nerd-font
  google-chrome
  firefox
  visual-studio-code
  slack
  spotify
  zoom
  arc
  microsoft-teams
  microsoft-auto-update
  1password
  chatgpt
  raycast
  whatsapp
  cloudflare-warp
  spotify
  discord
  slack
  notion
  zed
  alt-tab
  docker
  lulu
  eqmac
  battery
  hovrly
  audacity
  kyperkey
  middleclick
  mounty
  ollama
  telegram
  vlc
)
