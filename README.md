# Projects

Projects is a small bash script to store a list of project directories. Instead of having to type:

```sh
cd /home/username/some/really/long/project/name/thanks/golang
```

you can just type:

```sh
project cd awesome-project
```

It's a lot shorter, and less remembering.

## Installing

Installing is simple. Download the script and place it anywhere you like. In your .bashrc, add a `source` line to load the script. For example, if the script is at `/home/user/scripts/project.sh`, then add the line `source /home/user/script/project.sh`.

### ZSH

If you use oh-my-zsh, clone this repository into `$HOME/.oh-my.zsh/custom/plugins/project` with `git clone https://github.com/lfkeitel/project-list $HOME/.oh-my-zsh/custom/plugins/project`. Then add `project` to your plugin variable in `.zshrc`.

ZSH may error when project is ran for the first time, it's safe to ignore.

### macOS Users

This script relies on the GNU versions of realpath and grep. Because of this, you
will need to install `coreutils` and `grep`. These can be installed via Homebrew
with `brew install coreutils grep`.

## Usage

For usage information type `project help`.

To add a project:

```sh
project add project_name project_path
```

Or to use the current directory, simply omit the last argument:

```sh
project add project_name2
```

The only limitation is the project name cannot contain a colon. The project_path doesn't have to exist when you add it.

To remove a project:

```sh
project rm project_name
```

To cd to the project:

```sh
project cd project_name
```

To list known projects:

```sh
project ls
```

## Project Hooks

Project hooks allow you to run a script after changing directory into a project.
This can be used to activate a dev environment or startup your favorite code editor.
Project hooks are stored in `$HOME/.project-hooks.d` by default. This can be changed
by setting the `PROJECT_HOOKS_D` environment variable. The script doesn't need
to be executable as it's sourced by the shell, not executed like a normal script.
This is done so changes to the environment or sourcing other scripts works as
expected so the environment is properly setup.

Hooks can be created by making a file named `$PROJECT.sh` (replacing $PROJECT with
the project name) under the project hooks directory. You can also run
`project edit-hook $PROJECT` and the correct will be opened in the editor set
with `$EDITOR` or `vim` if `$EDITOR` is not defined.
