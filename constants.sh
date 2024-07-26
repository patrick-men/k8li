available_namespaces=($(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name))
available_resources=("po" "pod" "deploy" "deployment" "svc" "service" "ing" "ingress" "sec" "secret" "cm" "configmap" "ds" "daemonset" "no" "node" "tenant" "ma" "machine" "ms" "machineset" "md" "machinedeployment")
available_args=("wide" "w" "get" "g" "e" "edit" "logs" "l" "describe" "d" "bash" "b" "sh" "s" "yaml" "y" "follow" "f" "ip" "i" "rollout restart" "rr" "other")
