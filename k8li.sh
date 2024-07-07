#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Use that directory to source the other scripts
source "$DIR/funcs.sh"
source "$DIR/constants.sh"

parse_arguments "$@"

check_namespace

select_resource
select_action

name_fzf

execute_action