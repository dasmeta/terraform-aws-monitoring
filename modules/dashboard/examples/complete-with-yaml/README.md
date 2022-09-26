## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```


## Create Cloudwatch dashboard with yaml file.

For CloudWatch we can have multy type widgets.

When we want create widgets , we can use some defined types.

#### Text widgets
```
      {
        type : "text",
        content : "Nginx"
      }
```

#### Container/Inside metrics types( container/cpu, "container/memory", "container/restarts", "container/network" )

##### Min
```
      {
        type : "container/cpu",
        container : "nginx",
      }
```
##### Max
```
      {
        type : "container/cpu",
        container : "nginx",
        clustername: "dasmeta-test-new3"
        namespace: "default"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region: ""
      }
```

#### ALB/ELB metrics types( "traffic/5xx",  "traffic/4xx", "traffic/3xx")

##### Min
```
      {
        type : "traffic/5xx"
        loadbalancer : "app/fa5487/cd9b9f"
      },
```

##### Max
```
      {
        type : "traffic/5xx"
        loadbalancer : "app/fa5487/cd9b9f"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: "Sum"
        region:
      }
```

#### Application Base Metrics if you use Prometheus metrics( "application")

##### Min
```
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        container : "rpc-app-cont"
      }
```


##### Max (If  app name different from container name)
```
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        app : "rpc-app"
        container : "rpc-app-cont"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region:
      }
```

#### Log Base Metrics types ("log_base")

##### Min

```
      {
        type: "log_base"
        custom_namespaces: "LogInside"
        metric_name: "CloudTrail"
      }
```

##### Max

```
      {
        type: "log_base"
        custom_namespaces: "LogInside"
        metric_name: "CloudTrail"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region:
      }
```

#### Custom Metrics types ("custom")

##### Min
```
      {
        type: "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
      }
```

##### Max

```
      {
        type: "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region:
      }
```
