// Text
module "text" {
  source = "./modules/widget/text"
  text   = module.splite_config.text
}

// All Widget
module "all_widget" {
  count = length(module.splite_config.all_widget)

  source        = "./modules/widget/custom"
  custom_metric = module.splite_config.all_widget[count.index]
}
