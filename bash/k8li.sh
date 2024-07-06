#!/bin/bash

#TODO: Change this, so that it first asks for the resource type (if pod, then pod, if not one of a list of 5, then fzf through all resources)

# add flags to the script
if [ "$1" == "h" ] || [ "$1" == "help" ]; then
  echo "Usage: k8li [ARGS]"
  echo
  echo "Arguments:"
  echo "  h, help       Show this help message"
  echo "  l, logs       Show logs for a pod"
  echo "  d, describe   Describe a pod"
  echo "  b, bash       Open a bash shell in a pod"
  echo "  s, sh         Open a shell in a pod"
  echo "  y, yaml       Show the yaml for a pod"
  echo "  w, watch      Watch a pod"
  echo "  i, ip         Get the IP address of a pod"
  exit 0
fi

available_args=("l" "logs" "d" "describe" "b" "bash" "s" "sh" "y" "yaml" "w" "watch" "i" "ip")

# invalid inputs end the script
if [[ ! " ${available_args[@]} " =~ " $1 " ]]; then
  echo "Invalid argument"
  exit 1
fi

userchoice=$(kubectl get pods -A | tail -n +2 | awk '{printf "%-30s %s\n", $1, $2}' | fzf)

namespace=$(echo $userchoice | awk '{print $1}')
pod=$(echo $userchoice | awk '{print $2}')

case $1 in
  l|logs)
    kubectl logs $pod -n $namespace
    ;;
  d|describe)
    kubectl describe pod $pod -n $namespace
    ;;
  b|bash)
    kubectl exec -it $pod -n $namespace -- bash
    ;;
  s|sh)
    kubectl exec -it $pod -n $namespace -- sh
    ;;
  y|yaml)
    kubectl get pod $pod -n $namespace -o yaml
    ;;
  w|watch)
    kubectl get pod $pod -n $namespace -w
    ;;
  i|ip)
    kubectl get pod $pod -n $namespace -o jsonpath='{.status.podIP}'
    ;;
  *)
    echo "Invalid argument"
    ;;
esac
