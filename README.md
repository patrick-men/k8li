# k8li

`k8li` is a wrapper script that facilitates your common tasks when working with Kubernetes.

## Usage

`k8li` is designed as a tool to help you out with common tasks revolving a single resource. This is achieved by skipping the `kubectl get XY`, followed by copy pasting the name, and only then being able to run your desired command. Using `k8li`, you can do all that in a single command.

Thanks to [`fzf`](https://github.com/junegunn/fzf), it's possible to use both actions and resources outside of the ones listed below. This means that if you want more than the wrapper currently offers, or you make a typo, you'll receive a `fzf` with every resource and every action available on your cluster.

```text
k8li - A simple kubectl wrapper for common tasks
Usage: k8li [ACTION] [RESOURCE] [NAMESPACE]
Actions: The available arguments are the respective kubectl actions. The following are the most common ones:
  h, help               Show this help message
  w, wide               Show more information
  g, get                Get a resource
  l, logs               Show logs for a resource
  d, describe           Describe a resource
  b, bash               Open a bash shell in a pod
  s, sh                 Open a shell in a pod
  y, yaml               Show the yaml for a resource
  f, follow             Watch a resource
  i, ip                 Get the IP address of a resource
  rr, rollout restart   Restart a rollout
  other, typo           Opens a fzf for you to pick an action

Resources:
  po, pod               Interact with a pod
  deploy, deployment    Interact with a deployment
  svc, service          Interact with a service
  ing, ingress          Interact with an ingress
  no, node              Interact with a node
  secret                Interact with a secret
  cm, configmap         Interact with a configmap
  tenant                Interact with a tenant
  other, typo           Opens a fzf for you to pick your resource

Namespace:
  <empty>               Uses current namespace
  typo                  Opens a fzf for you to pick a namespace
  A                     Enables fzf through namespaces (-A)

```

## Installation

The easiest way to utilize `k8li` is by setting it as an alias:

``` bash
git clone https://github.com/patrick-men/k8li.git
cd k8li

# make the script executable
chmod +x k8li.sh

# if you're using bash
echo "alias k8li='$(pwd)/k8li.sh'" >> ~/.bashrc
source ~/.bashrc

# if you're using zsh
echo "alias k8li='$(pwd)/k8li.sh'" >> ~/.zshrc
source ~/.zshrc
```

> best is to run `git pull` every once in a while, as smaller patches/bigfixes are released spontaneously

If you plan on running `k8li` without an alias, consider following how-to's such as [this one](https://stackoverflow.com/questions/20054538/add-a-bash-script-to-path).