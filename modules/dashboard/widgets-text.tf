// Title
module "text_title" {
  source = "./modules/widgets/text/title"

  count = length(local.text_title)

  text = local.text_title[count.index].text
  y    = local.text_title[count.index].row
}

// Title with Link
module "text_title_with_link" {
  source = "./modules/widgets/text/title-with-link"

  count = length(local.text_title_with_link)

  text         = local.text_title_with_link[count.index].text
  link_to_jump = local.text_title_with_link[count.index].link_to_jump
  y            = local.text_title_with_link[count.index].row
}
