# Using [STOW 📂](https://www.gnu.org/software/stow/)

ℹ️ [**Medium Post** - Good guide](https://medium.com/quick-programming/managing-dotfiles-with-gnu-stow-9b04c155ebad)

## ➕ Adding dotfiles
1. Create a directory in the dotfiles folder with the name of the program you want to manage.
2. Move the dotfiles you want to manage to the directory you just created, maintaining the exact directory structure as in your home directory.
3. Run `stow <program>` to symlink the dotfiles to the home directory.

#### Example for Ghosty terminal:
   1. `cd dotfiles`
   2. `mkdir ghosty/.config`
   3. `touch ./ghosty/.config/config`
   4. `stow ghosty` 
   5. Now, a symlink for the `config` file will be created in `$HOME/.config/ghosty`

## ⬆️ Updating dotfiles
1. Update the dotfiles in the dotfiles folder.
2. Run `stow -R <program>` to update the symlinks.  
   *The `-R` option ensures old symlinks are cleaned up and new ones are created.*

## ⬇️ Using on a new machine
1. Clone the dotfiles repository.
2. Run `stow <program>` to symlink the dotfiles to the home directory.

## 🗑️ Removing dotfiles
1. Run `stow -D <program>` to remove the symlinks.
2. If you no longer need the program's dotfiles, you can delete the directory in the dotfiles folder (ensure it's backed up if needed).