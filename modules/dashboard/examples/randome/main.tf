module "dashboard" {
  //  source = "dasmeta/monitoring/aws//modules/dashboard"
  source = "../../"

  name = "Dashboard_name"

  defaults = {
    period : 300
    namespace : "default"
    clustername : "dasmeta-test-new3"
    width : 6
    height : 5
  }

  rows = [
    [
      // ROW1
      {
        type : "text",
        name : "Nginx"
      }
    ],
    // ROW2
    [
      {
        type : "container/cpu",
        period : 300,
        container : "nginx",
        clustername : "dasmeta-test-new3"
        name : "cpu"
        namespace : "default"
        width : 8
        height : 5
        period : 300
        statistic : "Average"
        region : "us-east-1"
      },
      {
        type : "container/restarts",
        container : "nginx",
        width : 8
        height : 5
      }
    ],
    // ROW3
    [
      {
        type : "text",
        content : "ELB"
      }
    ],
    // ROW4
    [
      {
        type : "traffic/5xx"
        loadbalancer : "app/fa5487/cd9b9f"
        name : "ALB 5xx"
        width : 8
        height : 5
        period : 300
        statistic : "Sum"
        region : "us-east-1"
      }
    ],
    // ROW5
    [
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        container : "rpc-app-cont"
        name : "Application Metric"
        app : "rpc-app"
        width : 8
        height : 5
        period : 300
        statistic : "Average"
        region : "us-east-1"
      },
      {
        type : "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
        name : "Custom Metric"
        width : 8
        height : 5
        period : 300
        statistic : "Average"
        region : "us-east-1"
      },
      {
        type : "container/network",
        container : "nginx",
      }
    ]
  ]
}
