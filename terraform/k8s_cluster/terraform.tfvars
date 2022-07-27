#################### Generic variables ####################

region         = "eastus"
env            = "blu"
k8s_version    = "1.21.9"
main_node_type = "standard_b2s" #standard_b2s
kubeconfig_path = "/home/joao-loureiro/.kube/config"
dockerconfig_path = "/home/joao-loureiro/.docker/config.json"

#################### AKS Variables ####################

aks = true

#################### EKS Variables ####################

eks = false

#################### GKE Variables ####################

gke = false