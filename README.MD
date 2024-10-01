### Using [STOW](https://www.gnu.org/software/stow/) 📂

ℹ️ [Medium Post - Good guide](https://medium.com/quick-programming/managing-dotfiles-with-gnu-stow-9b04c155ebad)

#### ➕ Adding dotfiles
1. Create a directory in the dotfiles folder with the name of the program you want to manage.
2. Move the dotfiles you want to manage to the directory you just created (maintain the directory structure).
3. Run `stow <program>` to symlink the dotfiles to the home directory.


#### ⬆️ Updating dotfiles
1. Update the dotfiles in the dotfiles folder.
2. Run `stow -R <program>` to update the symlinks.


#### ⬇️ Using in a new machine
1. Clone the dotfiles repository.
2. Run `stow <program>` to symlink the dotfiles to the home directory.


#### 🗑️ Removing dotfiles
1. Run `stow -D <program>` to remove the symlinks.
2. Delete the directory in the dotfiles folder.