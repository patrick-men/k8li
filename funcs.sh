#!/bin/bash

#######################################################################################################################
## For debugging: use set -x at the beginning of the script and/or remove all 2> redirects to see the error messages ##
#######################################################################################################################

#TOOD: refactor the if [ -t 1] > this is a check to see if the output is a terminal, required to be able to pipe the outputs into anything

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
    blue_text "Usage: k8li [ACTION] [RESOURCE] [NAMESPACE]"
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
    echo
    green_text "Namespace:"
    yellow_text "  <empty>               Uses current namespace"
    yellow_text "  ns, typo in namespace Opens a fzf for you to pick a namespace"
    yellow_text "  A                     Enables fzf through namespaces (-A)"
    echo
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

check_namespace() {
    if [[ $num_args == 3 && $namespace != "ns" && $namespace != "A" ]]; then
        if kubectl get namespace "$namespace" > /dev/null 2>&1; then
            query_namespace="-n $namespace"
        else
            namespace_list=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name)
            namespace=$(echo "$namespace_list" | fzf --prompt "Namespace: ")
            query_namespace="-n $namespace"
        fi
    elif [[ $num_args == 3 && $namespace == "ns" ]]; then
        namespace_list=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name)
        namespace=$(echo "$namespace_list" | fzf --prompt "Namespace: ")
        query_namespace="-n $namespace"
    elif [[ $num_args == 3 && $namespace == "A" ]]; then
        query_namespace="-A"
    else
        namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}')" || namespace="default"
        query_namespace=""
    fi

    if [ -t 1 ]; then
        # Output is a terminal, print the namespace
        if [[ $namespace == "A" ]]; then
            green_text "\nNamespace: all"
        else
            green_text "\nNamespace: $namespace"
        fi
    fi
}

# if resource isn't part of the list, then fzf through all resources
select_resource() {
    if [[ ! " ${available_resources[@]} " =~ " ${resource} " ]]; then
        resource=$(kubectl api-resources --no-headers | fzf --prompt "Resource: ")
        resource=$(echo "$resource" | awk '{print $1}')
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
    # if `kubectl get` fails, the error message is suppressed and the script continues
    output=$(kubectl get $resource $query_namespace 2>&1) || true
    
    if [[ $action == "g" || $action == "get" ]]; then
        name=""
    elif [[ -z "$output" ]]; then
        exit 1
    elif [[ $output =~ "No resources found" ]]; then
        red_text "The resource $resource does not exist in the namespace $namespace."
        exit 1
    elif [[ $query_namespace == "-A" ]]; then
        :
    else
        headers=$(echo "$output" | head -n 1)
        output=$(echo "$output" | tail -n +1)
        namespace_index=$(echo "$headers" | awk '{for(i=1; i<=NF; i++) if ($i == "NAMESPACE") print i}' 2>/dev/null)
        name_index=$(echo "$headers" | awk '{for(i=1; i<=NF; i++) if ($i == "NAME") print i}' 2>/dev/null)
        selected_line=$(echo "$output" | fzf --prompt "$resource: ")
        name=$(echo "$selected_line" | awk -v idx="$name_index" 'BEGIN{FS=" +"} {print $idx}' 2>/dev/null)
        namespace=$(echo "$selected_line" | awk -v idx="$namespace_index" 'BEGIN{FS=" +"} {print $idx}' 2>/dev/null)        
        
        if [[ $query_namespace == "" ]]; then
            :
        elif ! [[ $namespace == "" ]]; then
            query_namespace="-n $namespace"
        fi

        if [ -t 1 ]; then
            # Output is a terminal, print the selected resource
            green_text "Selected $resource: $name"
        fi
    fi
}

# function that executes the kubectl commands
execute_action() {
    timestamp=$(date +%Y%m%d%H%M%S)

    # case to handle the different actions - || only executes the echo if the command fails
    case $action in
    "w" | "wide")
        if [ -t 1 ]; then
            blue_text "Command: kubectl get $resource $name -o wide $query_namespace\n"
        fi
        kubectl get $resource $name -o wide $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "g" | "get")
        if [ -t 1 ]; then
            blue_text "Command: kubectl get $resource $name $query_namespace\n"
        fi
        kubectl get $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "l" | "logs")
        if [ -t 1 ]; then
            blue_text "Command: kubectl logs $name $query_namespace\n"
        fi
        kubectl logs $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "d" | "describe")
        if [ -t 1 ]; then
            blue_text "Command: kubectl describe $resource $name $query_namespace\n"
        fi
        kubectl describe $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "b" | "bash")
        if [[ $resource == "po" || $resource == "pod" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl exec -it $name $query_namespace -- bash\n"
            fi
            kubectl exec -it $name $query_namespace -- bash 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        else
            red_text "The resource $resource does not have a shell."
        fi
        ;;
    "s" | "sh")
        if [[ $resource == "po" || $resource == "pod" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl exec -it $name $query_namespace -- sh\n"
            fi
            kubectl exec -it $name $query_namespace -- sh 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        else
            red_text "The resource $resource does not have a shell."
        fi
        ;;
    "y" | "yaml")
        if [ -t 1 ]; then
            blue_text "Command: kubectl get $resource $name -o yaml $query_namespace\n"
        fi
        kubectl get $resource $name -o yaml $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "f" | "follow")
        if [ -t 1 ]; then
            blue_text "Command: kubectl get $resource $name -w $query_namespace\n"
        fi
        kubectl get $resource $name -w $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    "i" | "ip")
        if [[ $resource == "po" || $resource == "pod" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl get $resource $name -o jsonpath='{.status.podIP}' $query_namespace\n"
            fi
            kubectl get $resource $name -o jsonpath='{.status.podIP}' $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        elif [[ $resource == "svc" || $resource == "service" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl get $resource $name -o jsonpath='{.spec.clusterIP}' $query_namespace\n"
            fi
            kubectl get $resource $name -o jsonpath='{.spec.clusterIP}' $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        elif [[ $resource == "ing" || $resource == "ingress" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl get $resource $name -o jsonpath='{.status.loadBalancer.ingress[0].ip}' $query_namespace\n"
            fi
            kubectl get $resource $name -o jsonpath='{.status.loadBalancer.ingress[0].ip}' $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        elif [[ $resource == "no" || $resource == "node" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl get $resource $name -o jsonpath='{.status.addresses[?(@.type==\"InternalIP\")].address}' $query_namespace\n"
            fi
            kubectl get $resource $name -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        else
            red_text "The resource $resource does not have an IP address."
        fi
        ;;
    "rr" | "rollout restart")
        if [[ $resource == "deploy" || $resource == "deployment" ]]; then
            if [ -t 1 ]; then
                blue_text "Command: kubectl rollout restart $resource $name $query_namespace\n"
            fi
            kubectl rollout restart $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        else 
            red_text "The resource $resource does not support rollouts."
        fi
        ;;
    *)
        if [ -t 1 ]; then
            blue_text "Command: kubectl $action $resource $name $query_namespace\n"
        fi
        kubectl $action $resource $name $query_namespace 2>/tmp/k8li-error$timestamp || red_text "The command failed. Please check /tmp/k8li-error$timestamp for the error message."
        ;;
    esac
}