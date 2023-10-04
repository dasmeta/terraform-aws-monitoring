module "eks_monitoring_dashboard" {
  source = "./modules/dashboard/"

  count = length(var.eks_monitroing_dashboard) > 0 ? 1 : 0

  name = "eks_${var.name}"
  rows = var.eks_monitroing_dashboard
}
