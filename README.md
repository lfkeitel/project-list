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
