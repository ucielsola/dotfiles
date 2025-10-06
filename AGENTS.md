# Agent Guidelines for Dotfiles Repository

## Repository Structure
This is a dotfiles repository managed with GNU Stow. Each program has its own directory maintaining the exact structure as in the home directory.

## Build/Test Commands
- **Stow a config**: `stow <program>` (creates symlinks)
- **Update config**: `stow -R <program>` (restores symlinks)
- **Remove config**: `stow -D <program>` (removes symlinks)
- **Stow single file**: `stow --no-folding -t ~/.config/<target> <program>`

## Code Style & Conventions
- **Shell scripts**: Use bash shebang `#!/bin/bash`, UTF-8 encoding
- **Functions**: Use descriptive names with lowercase_underscore format
- **Aliases**: Use short, memorable abbreviations (e.g., `gs`, `ga`, `lg`)
- **Comments**: Use `#` with descriptive section headers like `# ----------------------`
- **Error handling**: Check for command existence with `command -v` before use
- **User prompts**: Use `read -r` for safe input, provide usage examples in error messages

## File Organization
- Config files go in `<program>/.config/<program>/` matching home directory structure
- Shell scripts for `$PATH` go in `bin/bin/` directory
- Aliases in `zsh/alias.sh`, git-specific in `zsh/git_alias.sh`
- Main zsh config in `zsh/.zshrc`

## Important Notes
- Never commit secrets (use 1Password CLI references)
- Maintain directory structure exactly as it appears in home directory
- Test symlinks with `ls -la ~/<path>` before committing
