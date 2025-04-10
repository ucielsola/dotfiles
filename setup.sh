#!/bin/bash
## RUN: curl -fsSL https://ucielsola.dev/setup -o setup.sh && bash setup.sh

# List of apps to install manually
## Longshot https://apps.apple.com/cn/app/longshot-screenshot-ocr/id6450262949
## Perplexity https://apps.apple.com/us/app/perplexity-ask-anything/id6714467650

# Make sure xcode command line tools are installed first (needed for Homebrew)
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  
  # Wait for xcode-select to be installed
  echo "Please complete the installation of Xcode Command Line Tools before continuing."
  echo "Press Enter when it's done..."
  read -r
fi

# Brew
## Install brew if not already installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  ## Enable brew in current shell and profile
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    # Check if the line already exists in .zprofile to avoid duplication
    if ! grep -q "eval \"\$(\/opt\/homebrew\/bin\/brew shellenv)\"" ~/.zprofile; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
  fi
else
  echo "Homebrew already installed, continuing..."
fi

### Create LaunchAgents dir
mkdir -p ~/Library/LaunchAgents

echo "Enabling autoupdate for homebrew packages (every 12 hours)..."
brew tap homebrew/autoupdate
brew autoupdate start 43200 --upgrade

echo "Updating and upgrading homebrew"
brew update
brew upgrade

# Install dockutil first as it's needed for dock configuration
echo "Installing dockutil..."
brew install dockutil

echo "Fetching Apps lists for Brew"
curl -fsSL https://raw.githubusercontent.com/ucielsola/dotfiles/refs/heads/main/brew_apps -o /tmp/brew_apps
curl -fsSL https://raw.githubusercontent.com/ucielsola/dotfiles/refs/heads/main/brew_casks -o /tmp/brew_casks

echo "Installing apps with Brew"
brew install $(</tmp/brew_apps)
brew install --cask $(</tmp/brew_casks)

# Check if 1Password CLI is available before trying to use it
if command -v op &>/dev/null; then
  echo "Setting up SSH keys with 1Password..."
  
  # Check if already signed in to 1Password
  if ! op account list &>/dev/null; then
    echo "Please sign in to 1Password CLI..."
    eval "$(op signin)"
  fi

  # Create the .ssh directory if it doesn't exist
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Fetch GitHub private key
  op read "op://SSH/GITHUB/private key" -o ~/.ssh/id_rsa_github
  chmod 600 ~/.ssh/id_rsa_github

  # Fetch GitHub public key
  op read "op://SSH/GITHUB/public key" -o ~/.ssh/id_rsa_github.pub

  # Fetch GitLab private key
  op read "op://SSH/GITLAB/private key" -o ~/.ssh/id_rsa_gitlab
  chmod 600 ~/.ssh/id_rsa_gitlab

  # Fetch GitLab public key
  op read "op://SSH/GITLAB/public key" -o ~/.ssh/id_rsa_gitlab.pub

  # Add the private keys to the SSH agent
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_rsa_github
  ssh-add ~/.ssh/id_rsa_gitlab

  echo "Creating known_hosts file..."

  # Backup existing known_hosts (if any)
  if [ -f ~/.ssh/known_hosts ]; then
    mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
  fi

  # Add GitHub and GitLab host keys
  ssh-keyscan github.com >> ~/.ssh/known_hosts
  ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

  echo "Creating SSH config file..."

  cat > ~/.ssh/config <<EOF
# GitHub
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_github

# GitLab
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_rsa_gitlab
EOF

  chmod 600 ~/.ssh/config
  echo "SSH setup completed successfully!"
else
  echo "1Password CLI not found. Skipping SSH keys setup."
fi

# Setup the Dock
echo "Configuring Dock..."
if command -v dockutil &>/dev/null; then
  dockutil --remove all --no-restart
  
  # Check if the apps exist before adding them
  [ -d "/Applications/Arc.app" ] && dockutil --add "/Applications/Arc.app" --no-restart
  [ -d "/Applications/Visual Studio Code.app" ] && dockutil --add "/Applications/Visual Studio Code.app" --no-restart
  [ -d "/Applications/Ghostty.app" ] && dockutil --add "/Applications/Ghostty.app" --no-restart
  [ -d "/System/Applications/System Settings.app" ] && dockutil --add "/System/Applications/System Settings.app" --no-restart
  
  dockutil --add '~/Downloads' --view list --display folder --no-restart
  dockutil --add "~/.Trash" --no-restart
  
  # Actually apply the dockconfig function
  echo "Setting up permanent dock auto-hide"
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0
  defaults write com.apple.dock static-only -bool false
  
  # Dock tweaks
  defaults write com.apple.dock orientation -string left # Move dock to left side of screen
  defaults write com.apple.dock show-recents -bool FALSE # Disable "Show recent applications in dock"
  defaults write com.apple.Dock showhidden -bool TRUE    # Show hidden applications as translucent
  
  # Restart Dock to apply changes
  killall Dock
else
  echo "dockutil not found. Skipping Dock configuration."
fi

# Git configuration
echo "Configuring Git..."
git config --global user.name "Uciel Sola"
# Add email prompt
read -p "Enter your Git email address: " git_email
if [ -n "$git_email" ]; then
  git config --global user.email "$git_email"
fi

echo "Configuring macOS settings..."
# Avoid the creation of .DS_Store files on network volumes or USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Finder tweaks
defaults write NSGlobalDomain AppleShowAllExtensions -bool true            # Show all filename extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable warning when changing a file extension
defaults write com.apple.finder FXPreferredViewStyle Clmv                  # Use column view
defaults write com.apple.finder AppleShowAllFiles -bool true               # Show hidden files
defaults write com.apple.finder ShowPathbar -bool true                     # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true                   # Show status bar
killall Finder

# Cleanup
echo "Removing dockutil after setup"
brew remove dockutil

echo "Setup completed successfully!"
