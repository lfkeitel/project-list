#!/bin/bash

project() {
local PROJECT_LIST=${PROJECT_LIST:-$HOME/.project.list}

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
    read -r -p "Would you like to make it? $PROJECT_LIST [Y/n] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        makeNewListFile
        return $?
    elif [ -z "$response" ]; then
        makeNewListFile
        return $?
    else
        return 1
    fi
}

projectExists() {
    project="$(grep -P "^$1:" "$PROJECT_LIST")"
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

    if [ -z "$project_name" -o -z "$project_path" ]; then
        usage
        return
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
    echo "${project_name}:${project_path}" >> "$PROJECT_LIST"
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
        echo "Project $1 doesn't exist"
        return
    fi

    newList="$(grep -vP "^$1:" "$PROJECT_LIST")"
    echo "$newList" > "$PROJECT_LIST"
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

    IFS=':' read -r -a projectsArr <<< "$projects"

    if [ ${#projectsArr[@]} -eq 1 ]; then
        cd "${projectsArr[0]}"
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
    *)
        usage
esac
}
