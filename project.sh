#!/bin/bash

project() {
local PROJECT_LIST=${PROJECT_LIST:-$HOME/.project.list}

confirmPrompt() {
    if [[ "$SHELL" =~ "zsh" ]]; then
        read "response?$1 [y/N]? "
    else
        read -r -p "$1 [y/N]? " response
    fi

    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "y"
        return
    fi
    echo "n"
}

makeNewListFile() {
    mkdir -p "$(dirname $PROJECT_LIST)"
    if [ $? -ne 0 ]; then
        echo "Error creating file."
        return 1
    fi

    touch "$PROJECT_LIST"
    if [ $? -ne 0 ]; then
        echo "Error creating file."
        return 1
    fi

    echo "Project file created"
}

promptNewListFile() {
    echo "Project list doesn't exist."
    response="$(confirmPrompt "Would you like to make it? $PROJECT_LIST")"
    if [ "$response" = "y" ]; then
        makeNewListFile
        return $?
    fi

    return 1
}

projectExists() {
    project="$(grep -P "^$1:" "$PROJECT_LIST")"
    [ -z "$project" ]
    return $?
}

checkProjectPathExists() {
    project="$(grep -P ":$1$" "$PROJECT_LIST")"
    [ -z "$project" ]
    return $?
}

checkProjectName() {
    [ -z "$(echo "$1" | grep ':')" ]
    return $?
}

addProjectToList() {
    project_name="$1"
    project_path="$2"

    if [ -z "$project_name" ]; then
        promptName="$(basename $PWD)"
        echo "No project name given."
        response="$(confirmPrompt "Would you like to use $promptName")"
        if [ "$response" = "y" ]; then
            project_name="$promptName"
        else
            return
        fi
    fi

    if [ -z "$project_path" ]; then
        echo "No path given, using current directory"
        project_path="$PWD"
    fi

    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    projectExists "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project $project_name already exists"
        return
    fi

    project_path="$(realpath $project_path)"

    checkProjectPathExists "$project_path"
    if [ $? -ne 0 ]; then
        echo "Project path $project_path already exists"
        response="$(confirmPrompt "Would you like to add a duplicate project?")"
        if [ "$response" != "y" ]; then
            return
        fi
    fi

    echo "${project_name}:${project_path}" >> "$PROJECT_LIST"
    sortProjectList
}

removeProjectFromList() {
    project_name="$1"
    if [ -z "$project_name" ]; then
        usage
        return
    fi

    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    projectExists "$project_name"
    if [ $? -eq 0 ]; then
        return
    fi

    newList="$(grep -vP "^$1:" "$PROJECT_LIST")"
    echo "$newList" > "$PROJECT_LIST"
}

sortProjectList() {
    cp "$PROJECT_LIST" /tmp/project.list
    cat /tmp/project.list | sort > "$PROJECT_LIST"
    rm -f /tmp/project.list
}

listAllProjects() {
    echo "Projects:"
    awk -F: '{ printf "  "; \
        printf $1; \
        printf " -> "; \
        print $2 }' "$PROJECT_LIST"
}

searchForProjects() {
    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    echo "Projects:"
    grep -P "^[^:]*?$1[^:]*?:" "$PROJECT_LIST" | \
        awk -F: '{ printf "  "; \
            printf $1; \
            printf " -> "; \
            print $2 }'
}

changeToProjectDir() {
    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    grep_regex="^[^:]*?$1[^:]*?:"
    projects="$(grep -P "$grep_regex" "$PROJECT_LIST" | \
        awk -F: '{ printf $2; printf ":" }')"
    projects="${projects%?}"

    if [[ "$SHELL" =~ "zsh" ]]; then
        IFS=':' read -r -A projectsArr <<< "$projects"
    else
        IFS=':' read -r -a projectsArr <<< "$projects"
    fi

    if [ ${#projectsArr[@]} -eq 1 ]; then
        cd "${projectsArr}"
        return
    fi

    projectsArr+=("cancel")
    dest=""
    select d in "${projectsArr[@]}"; do
        case $d in
        "cancel")
            return
            ;;
        *)
            dest=$d
            break
            ;;
        esac
    done

    if [ ! -d "$dest" ]; then
        echo "Project directory $dest doesn't exist."
        return
    fi

    cd "$dest"
}

usage() {
    echo "Usage: project.sh COMMAND project_name [project_path]"
    cat <<"EOF"

Commands:
    add|a        Add a new project to the list
    remove|rm|r  Remove a project from the list
    search|s     Search for projects by name
    list|ls      List all projects
    cd           Change directory into project
EOF
}

showVersion() {
    cat <<"EOF"
project-list - v1.6.0

Copyright 2017 Lee Keitel <lee@onesimussystems.com>

This software is distributed under the BSD 3-clause license.
EOF
}

if [ ! -f "$PROJECT_LIST" ]; then
    promptNewListFile
    if [ $? -ne 0 ]; then
        return
    fi
fi

case "$1" in
    cd)
        shift; changeToProjectDir $@;;
    list|ls)
        shift; listAllProjects $@;;
    search|s)
        shift; searchForProjects $@;;
    add|a)
        shift; addProjectToList $@;;
    remove|rm|r)
        shift; removeProjectFromList $@;;
    version|ver|v)
        shift; showVersion $@;;
    *)
        usage
esac
}

# If invoked as a normal script, execute with arguments
if [ "$#" -gt 0 ]; then
    project "$@"
fi
