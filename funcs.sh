#!/bin/bash

# functions to add color to outputs
color_reset=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)

red_text() {
    echo -e "${red}$1${color_reset}"
}

green_text() {
    echo -e "${green}$1${color_reset}"
}

yellow_text() {
    echo -e "${yellow}$1${color_reset}"
}

blue_text() {
    echo -e "${blue}$1${color_reset}"
}

# help message 
display_help() {
    blue_text "k8li - A simple kubectl wrapper for common tasks"
    echo
    blue_text "Usage: k8li [ACTION] [RESOURCE]"
    echo
    green_text "Actions: The available arguments are the respective kubectl actions. The following are the most common ones:"
    yellow_text "  h, help               Show this help message"
    yellow_text "  w, wide               Show more information"
    yellow_text "  g, get                Get a resource"
    yellow_text "  l, logs               Show logs for a resource"
    yellow_text "  d, describe           Describe a resource"
    yellow_text "  b, bash               Open a bash shell in a pod"
    yellow_text "  s, sh                 Open a shell in a pod"
    yellow_text "  y, yaml               Show the yaml for a resource"
    yellow_text "  f, follow             Watch a resource"
    yellow_text "  i, ip                 Get the IP address of a resource"
    yellow_text "  rr, rollout restart   Restart a rollout"
    yellow_text "  other                 Opens a fzf for you to pick an action"
    echo 
    green_text "Resources:"
    yellow_text "  po, pod               Interact with a pod"
    yellow_text "  deploy, deployment    Interact with a deployment"
    yellow_text "  svc, service          Interact with a service"
    yellow_text "  ing, ingress          Interact with an ingress"
    yellow_text "  no, node              Interact with a node"
    yellow_text "  secret                Interact with a secret"
    yellow_text "  cm, configmap         Interact with a configmap"
    yellow_text "  tenant                Interact with a tenant"
    echo 
    yellow_text "  any other resource    Opens a fzf for you to pick your resource"
    exit 0
}

# function to parse the arguments passed to the script
parse_arguments() {
    # get the amount of arguments passed
    num_args=$#

    # if there are exactly three arguments, assume that the namespace was provided
    if [ $# -eq 3 ]; then
        resource=${@: -2:1}
        action=${@:1:$#-2}
        namespace=${@: -1}

    # if there are exactly two arguments, assume that no namespace was provided
    elif [ $num_args -eq 2 ]; then
        resource=${@: -1}
        action=${@: -2:1}
        namespace=""
    
    # in any other case, show the help message
    else
        display_help
        exit 0
    fi
}

# check if a namespace was provided and if it exists
check_namespace() {
    if [[ $num_args == 3 && -n $(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | grep -i "$namespace") ]]; then
        query_namespace="-n $namespace"
    elif [[ $num_args == 3 && -z $(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | grep -i "$namespace") ]]; then
        namespace=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | fzf --prompt "Namespace: ")
        query_namespace="-n $namespace"
    else
        namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}')" || namespace="default"
        query_namespace=""
    fi

    green_text "\nNamespace: $namespace"
}

# if resource isn't part of the list, then fzf through all resources
select_resource() {
    if [[ ! " ${available_resources[@]} " =~ " ${resource} " ]]; then
        resource=$(kubectl api-resources --no-headers | awk '{print $1}' | fzf --prompt "Resource: ")
    fi
}

# if action isn't part of the list, then fzf through all actions
select_action() {
    if [[ ! " ${available_args[@]} " =~ " ${action} " ]]; then

        # fzf through the available actions; only show every other element in the array (long names)
        action=$(for ((i=0; i<${#available_args[@]}; i+=2)); do
            echo "${available_args[$i]}"
        done | fzf --prompt "Action1: ")
        
        if [[ "$action" == "other" ]]; then
            action=$(kubectl --help | grep '^  ' | awk '{print $1}' | awk 'NR > 1 {print last} {last = $0}' | fzf --prompt "Action: ")
        fi
    fi
}

# function that takes the kubectl output and runs fzf on the names
name_fzf() {
    output=$(kubectl get $resource $query_namespace | awk 'NR>1 {print $1}')
    if [[ -z "$output" ]]; then
        exit 1
    else
        name=$(echo "$output" | fzf --prompt "$resource: ")
        green_text "Selected $resource: $name\n"    
    fi
}

# function that executes the kubectl commands
execute_action() {
    timestamp=$(date +%Y%m%d%H%M%S)

    # case to handle the different actions - || only executes the echo if the command fails
    case $action in
    "w" | "wide")
        blue_text "Command: kubectl get $resource $name -o wide $query_namespace\n"
        kubectl get $resource $name -o wide $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "g" | "get")
        blue_text "Command: kubectl get $resource $name $query_namespace\n"
        kubectl get $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "l" | "logs")
        blue_text "Command: kubectl logs $resource $name $query_namespace\n"
        kubectl logs $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "d" | "describe")
        blue_text "Command: kubectl describe $resource $name $query_namespace\n"
        kubectl describe $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "b" | "bash")
        blue_text "Command: kubectl exec -it $name $query_namespace -- bash\n"
        kubectl exec -it $name $query_namespace -- bash 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "s" | "sh")
        blue_text "Command: kubectl exec -it $name $query_namespace -- sh\n"
        kubectl exec -it $name $query_namespace -- sh 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "y" | "yaml")
        blue_text "Command: kubectl get $resource $name -o yaml $query_namespace\n"
        kubectl get $resource $name -o yaml $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "f" | "follow")
        blue_text "Command: kubectl get $resource $name -w $query_namespace\n"
        kubectl get $resource $name -w $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "i" | "ip")
        blue_text "Command: kubectl get $resource $name -o jsonpath='{.status.podIP}' $query_namespace\n"
        kubectl get $resource $name -o jsonpath='{.status.podIP}' $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "rr" | "rollout restart")
        blue_text "Command: kubectl rollout restart $resource $name $query_namespace\n"
        kubectl rollout restart $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    *)
        blue_text "Command: kubectl $action $resource $name $query_namespace\n"
        kubectl $action $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    esac
}