module "eks_monitoring_dashboard" {
  source  = "dasmeta/monitoring/aws//modules/dashboard"
  version = "1.5.1"

  count = length(var.eks_monitroing_dashboard) > 0 ? 1 : 0

  name = "eks_${var.name}"
  rows = var.eks_monitroing_dashboard
}
