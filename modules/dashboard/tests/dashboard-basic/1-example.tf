# this is going to create emplty dashboard
module "basic-dashboard" {
  source = "../../"
  name   = "Basic-Dashboard"
  rows   = []
}

# this is going to create dashboard with text widgets
module "basic-dashboard-with-text" {
  source = "../../"
  name   = "Basic-Dashboard-with-text"
  rows = [
    [
      {
        type : "text/title"
        text : "Row 1 / col 1"
      }
    ],
    [
      {
        type : "text/title"
        text : "Row 2 / col 1"
      }
    ]
  ]
}
