# this is going to create rds dashboard

module "dashboard_rds" {
  source = "../../"

  name = "test-rds"
  rows = [
    [
      {
        type : "text/title"
        text : "rds-dev"
      }
    ],
    [
      {
        type : "rds/cpu",
        period : 300,
        rds_name : "rds-dev",
      },
      {
        type : "rds/memory",
        period : 300,
        rds_name : "rds-dev",
      },
      {
        type : "rds/disk",
        period : 300,
        rds_name : "rds-dev",
      },
      {
        type : "rds/connections",
        period : 300,
        rds_name : "rds-dev",
      },
    ]
  ]
}
