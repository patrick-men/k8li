#!/bin/bash

#TODO: Better README.md

#TODO: change this in a way that it ends up working/making sense for things that only affect a single pod.
# such as logs, describe, exec, etc.

# get the amount of arguments passed
num_args=$#

# check how many args were passed
if [ $# -eq 0 ]; then
  echo "No arguments provided. Run 'k8li h' for help"
  exit 1
elif [ $num_args -eq 2 ]; then
  # if there are only two arguments, assume that no namespace was provided
  resource=${@: -1}
  action=${@: -2:1}
  namespace=""
else
  # if there are more than two arguments, assume that the last argument is the namespace
  resource=${@: -2:1}
  action=${@:1:$#-2}
  namespace=${@: -1}
fi

# add flags to the script
if [ "$action" == "h" ] || [ "$action" == "help" ]; then
  echo "k8li - A simple kubectl wrapper for common tasks"
  echo
  echo "Usage: k8li [ACTION] [RESOURCE]"
  echo
  echo "Actions: The available arguments are the respective kubectl actions. The following are the most common ones:"
  echo "  h, help               Show this help message"
  echo "  w, wide               Show more information"
  echo "  g, get                Get a resource"
  echo "  l, logs               Show logs for a resource"
  echo "  d, describe           Describe a resource"
  echo "  b, bash               Open a bash shell in a pod"
  echo "  s, sh                 Open a shell in a pod"
  echo "  y, yaml               Show the yaml for a resource"
  echo "  f, follow             Watch a resource"
  echo "  i, ip                 Get the IP address of a resource"
  echo "  rr, rollout restart   Restart a rollout"
  echo 
  echo "Resources:"
  echo "  po, pod               Interact with a pod"
  echo "  deploy, deployment    Interact with a deployment"
  echo "  svc, service          Interact with a service"
  echo "  ing, ingress          Interact with an ingress"
  echo "  no, node              Interact with a node"
  echo "  secret                Interact with a secret"
  echo "  cm, configmap         Interact with a configmap"
  echo "  tenant                Interact with a tenant"
  echo 
  echo "  any other resource    Opens a fzf for you to pick your resource"
  exit 0
fi

# convert the available namespaces to an array
available_namespaces=($(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name))

# check if a namespace was provided
if [[ -n "$namespace" ]]; then
  # if a namespace was provided, check if it exists in the list of available namespaces
  if [[ " ${available_namespaces[@]} " =~ " ${namespace} " ]]; then
    # if the namespace exists, set query_namespace to "-n $namespace"
    query_namespace="-n $namespace"
  else
    # if the namespace doesn't exist, ask the user to select a namespace
    namespace=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | fzf --prompt "Namespace: ")
    query_namespace="-n $namespace"
  fi
else
  # if no namespace was provided, set query_namespace to an empty string
  query_namespace=""
fi


# check if a namespace was provided and if it exists
if [[ $num_args == 3 && -n $(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | grep -i "$namespace") ]]; then
  query_namespace="-n $namespace"
elif [[ $num_args == 3 && -z $(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | grep -i "$namespace") ]]; then
  namespace=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name | fzf --prompt "Namespace: ")
  query_namespace="-n $namespace"
else
  query_namespace=""
fi

available_resources=("po" "pod" "deploy" "deployment" "svc" "service" "ing" "ingress" "sec" "secret" "cm" "configmap" "no" "node" "tenant")
available_args=("w" "wide" "g" "get" "l" "logs" "d" "describe" "b" "bash" "s" "sh" "y" "yaml" "f" "follow" "i" "ip" "rr" "rollout restart")

# if resource isn't part of the list, then fzf through all resources
if [[ ! " ${available_resources[@]} " =~ " ${resource} " ]]; then
  resource=$(kubectl api-resources --no-headers | awk '{print $1}' | fzf --prompt "Resource: ")
fi

# if action isn't part of the list, then fzf through all actions - else, execute the action
if [[ ! " ${available_args[@]} " =~ " ${action} " ]]; then
  # fzf through all actions
  action=$(kubectl --help | grep '^  ' | awk '{print $1}' | awk 'NR > 1 {print last} {last = $0}' | fzf --prompt "Action: ")
  echo "hehehe"
fi

# case to handle the different actions
case $action in
  "w" | "wide")
    kubectl get $resource -o wide $query_namespace
    ;;
  "g" | "get")
    kubectl get $resource $query_namespace
    ;;
  "l" | "logs")
    kubectl logs $resource $query_namespace
    ;;
  "d" | "describe")
    kubectl describe $resource $query_namespace
    ;;
  "b" | "bash")
    kubectl exec -it $resource $query_namespace -- bash
    ;;
  "s" | "sh")
    kubectl exec -it $resource $query_namespace -- sh
    ;;
  "y" | "yaml")
    kubectl get $resource -o yaml $query_namespace
    ;;
  "f" | "follow")
    kubectl get $resource -w $query_namespace
    ;;
  "i" | "ip")
    kubectl get $resource -o jsonpath='{.status.podIP}' $query_namespace
    ;;
  "rr" | "rollout restart")
    kubectl rollout restart $resource $query_namespace
    ;;
  *)
    kubectl $action $resource $query_namespace
    ;;
esac
