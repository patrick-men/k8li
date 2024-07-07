available_namespaces=($(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name))
available_resources=("po" "pod" "deploy" "deployment" "svc" "service" "ing" "ingress" "sec" "secret" "cm" "configmap" "no" "node" "tenant")
available_args=("wide" "w" "get" "g" "logs" "l" "describe" "d" "bash" "b" "sh" "s" "yaml" "y" "follow" "f" "ip" "i" "rollout restart" "rr" "other")