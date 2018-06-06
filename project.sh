#!/bin/bash

project() {
local PROJECT_LIST=${PROJECT_LIST:-$HOME/.project.list}
local PROJECT_HOOKS_D=${PROJECT_HOOKS_D:-$HOME/.project-hooks.d}
local PEDITOR=${PEDITOR:-vim}
local SYSTEM_TYPE="$(uname)"

local GREP_CMD="grep"
if [[ $SYSTEM_TYPE = "Darwin" ]]; then
    GREP_CMD="ggrep"
fi

local REALPATH_CMD="realpath"
if [[ $SYSTEM_TYPE = "Darwin" ]]; then
    REALPATH_CMD="grealpath"
fi

# Prompt with a default of no
confirmPromptN() {
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

# Prompt with a default of yes
confirmPromptY() {
    if [[ "$SHELL" =~ "zsh" ]]; then
        read "response?$1 [Y/n]? "
    else
        read -r -p "$1 [Y/n]? " response
    fi

    if [[ $response =~ ^([nN][oO]|[nN])$ ]]; then
        echo "n"
        return
    fi
    echo "y"
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
    response="$(confirmPromptY "Would you like to make it? $PROJECT_LIST")"
    if [ "$response" = "y" ]; then
        makeNewListFile
        return $?
    fi

    return 1
}

projectExists() {
    project="$($GREP_CMD -P "^$1:" "$PROJECT_LIST")"
    [ -z "$project" ]
    return $?
}

checkProjectPathExists() {
    project="$($GREP_CMD -P ":$1$" "$PROJECT_LIST")"
    [ -z "$project" ]
    return $?
}

checkProjectName() {
    [ -z "$(echo "$1" | $GREP_CMD ':')" ]
    return $?
}

addProjectToList() {
    project_name="$1"
    project_path="$2"

    if [ -z "$project_name" ]; then
        promptName="$(basename $PWD)"
        echo "No project name given."
        response="$(confirmPromptY "Would you like to use $promptName")"
        if [ "$response" = "y" ]; then
            project_name="$promptName"
        else
            return
        fi
    fi

    if [ -z "$project_path" ]; then
        project_path="$PWD"
    fi

    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    projectExists "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name $project_name already exists"
        response="$(confirmPromptN "Would you like to update the project path?")"
        if [ "$response" != "y" ]; then
            return
        fi

        removeProjectFromList "$project_name"
    fi

    project_path="$($REALPATH_CMD $project_path)"

    checkProjectPathExists "$project_path"
    if [ $? -ne 0 ]; then
        echo "Project path $project_path already exists"
        response="$(confirmPromptN "Would you like to add a duplicate project?")"
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

    newList="$($GREP_CMD -vP "^$1:" "$PROJECT_LIST")"
    echo "$newList" > "$PROJECT_LIST"
}

sortProjectList() {
    cp "$PROJECT_LIST" /tmp/project.list
    cat /tmp/project.list | sort > "$PROJECT_LIST"
    rm -f /tmp/project.list
}

listAllProjects() {
    echo "Projects:"
    awk -F: '{ print "  " $1 "\t" $2 }' "$PROJECT_LIST" | column -t -s $'\t'
}

searchForProjects() {
    project_name="$1"
    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    echo "Projects:"
    $GREP_CMD -P "^[^:]*?${project_name}[^:]*?:" "$PROJECT_LIST" | \
        awk -F: '{ print "  " $1 "\t" $2 }' | column -t -s $'\t'
}

changeToProjectDir() {
    project_name="$1"
    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    grep_regex="^[^:]*?${project_name}[^:]*?:"
    projects="$($GREP_CMD -P "$grep_regex" "$PROJECT_LIST" | \
        awk -F: '{ printf $2; printf ":" }')"
    projects="${projects%?}"

    if [[ "$SHELL" =~ "zsh" ]]; then
        IFS=':' read -r -A projectsArr <<< "$projects"
    else
        IFS=':' read -r -a projectsArr <<< "$projects"
    fi

    if [ ${#projectsArr[@]} -eq 1 ]; then
        project_name="$($GREP_CMD "${projectsArr}" $PROJECT_LIST | cut -d':' -f1)"
        cd "${projectsArr}"
        run_project_hooks "$project_name"
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

    project_name="$($GREP_CMD "${dest}" $PROJECT_LIST | cut -d':' -f1)"
    cd "$dest"
    run_project_hooks "$project_name"
}

edit_project_hook() {
    project_name="$1"
    checkProjectName "$project_name"
    if [ $? -ne 0 ]; then
        echo "Project name cannot contain a colon."
        return
    fi

    projectExists "$project_name"
    if [ $? -eq 0 ]; then
        echo "Project $project_name doesn't exist."
        return
    fi

    if [ ! -d "$PROJECT_HOOKS_D" ]; then
        mkdir -p "$PROJECT_HOOKS_D"
    fi

    $PEDITOR "$PROJECT_HOOKS_D/$project_name.sh"
}

run_project_hooks() {
    if [ -f "$PROJECT_HOOKS_D/$1.sh" ]; then
        source "$PROJECT_HOOKS_D/$1.sh"
    fi
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
    edit-hook|eh Edit the hook script when entering a project
EOF
}

showVersion() {
    cat <<"EOF"
project-list - v1.7.0

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
    edit-hook|eh)
        shift; edit_project_hook $@;;
    *)
        usage
esac
}

# If invoked as a normal script, execute with arguments
if [ "$#" -gt 0 ]; then
    project "$@"
fi
