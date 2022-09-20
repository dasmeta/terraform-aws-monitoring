module "splite_config" {
  source = "./modules/splite_config"
  rows   = var.dashboard["rows"]
}
