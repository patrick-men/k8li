#!/bin/bash

#TODO: add colors to the output

source funcs.sh
source constants.sh

parse_arguments "$@"

check_namespace

select_resource
select_action

name_fzf


execute_action