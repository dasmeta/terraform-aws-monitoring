// Title
module "text_title" {
  source = "./modules/widgets/text/title"

  count = length(local.text_title)

  text = local.text_title[count.index].text
  y    = local.text_title[count.index].row
}
