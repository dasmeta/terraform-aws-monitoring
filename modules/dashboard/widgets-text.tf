// Title
module "text_title" {
  source = "./modules/widgets/text/title"

  count = length(local.widget_config["text/title"])

  text = local.widget_config["text/title"][count.index].text
  y    = local.widget_config["text/title"][count.index].row
}
