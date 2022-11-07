output "data" {
  value = try(
    module.base_cloudwatch[0].data,
    module.base_grafana[0].data,
    null
  )
}
