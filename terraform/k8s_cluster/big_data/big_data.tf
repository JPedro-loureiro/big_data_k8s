#################### Helm Provider ####################

provider "helm" {
  kubernetes {
    host                   = var.host
    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

#################### Nginx Ingress Controller ####################

resource "helm_release" "nginx_ingress_controller" {
  name             = "nginx-ingress-controller"
  namespace        = "nginx-ingress-controller"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"

  set {
    name  = "controller.service.loadBalancerIP"
    value = var.load_balancer_ip
  }

  # To get de FQDN run:
  # az network public-ip list --resource-group bigDataOnK8s-nodeResourceGroup --query "[?name=='aks-ingress-ip'].[dnsSettings.fqdn]" -o tsv
  set {
    name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-dns-label-name\""
    value = "k8s-${var.env}"
  }
}