## 1. How to debug test applications
./tests/basic/app folder contains test apps.

Test apps can be debugged using docker-compose.yaml.
Default config will log traces to stdout so application tracing can be tested there.

Note: Tempo source being configured to push metrics with prometheus. Prometheus url needs to be provided when deploying Tempo.

## 2. How to build and push test application images
In order to test on eks cluster we need to build images which can be done using following commands.
```
cd ./tests/basic/app/test-app
docker build . -t xxxxxxxxxxx.dkr.ecr.eu-central-1.amazonaws.com/test-app:0.1.9
docker push xxxxxxxxxxx.dkr.ecr.eu-central-1.amazonaws.com/test-app:0.1.9
```

## 3. How to setup otel to accept traces and send to x-ray & grafana
In order to get application traces into x-ray or grafana otel-collector (ADOT) needs to be configured to accept and then send traces to right services.
Otel is configured in blueprint.development.iac repo, branch NEMCRM-1748-tracing in
`blueprint.development.iac/terraform/sandboxes/ak/conf.d/adot.yaml`.

## 3.1 How to configure grafana sources
This is yet done manually, but should be managed via terraform.
Requires:
1. Prometheus source be created
2. Tempo source be created
3. Tempo needs to be configured to use prometheus.

## 4. How to deploy test applications onto the EKS
After pushing images to registry following command will deploy test applications into EKS cluster:

```
cd ./tests/basic/app/helm/test-app
helm upgrade --install test-js-service-1 -f service-1-values.yaml .
helm upgrade --install test-js-service-2 -f service-2-values.yaml .
helm upgrade --install test-js-service-1 -f service-1-values.yaml .
```

## 5. How to deploy test lambda into AWS to be used in the chain
Lambda is used in the chain and can be deployed with those commands.
Actual lambda is created manually via AWS Web Console.

```
cd ./tests/basic/lambda
rm test-tracing-lambda.zip && zip -r test-tracing-lambda.zip . && aws lambda update-function-code --function-name test-tracing-lambda \
--zip-file fileb:///home/tigran/projects/devops/pro-alpha/tests/lambda/test-tracing-lambda.zip
```

## module allows to deploy grafana stack tools into EKS

### TODO: clean passwords for aws iam users
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 2.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki_bucket"></a> [loki\_bucket](#module\_loki\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.8.2 |
| <a name="module_tempo_bucket"></a> [tempo\_bucket](#module\_tempo\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.8.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.grafana_stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.grafana_stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adminPassword"></a> [adminPassword](#input\_adminPassword) | The initial admin user password for using to login into grafana ui | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create kubernetes namespace for grafana stack helm release | `bool` | `true` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The arn of oidc provider for eks cluster | `string` | n/a | yes |
| <a name="input_host"></a> [host](#input\_host) | The ingress host name to have grafana ui available via load balancer | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | grafana stack release name | `string` | `"grafana-stack"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The kubernetes namespace where grafana-stuck release will be created/installed | `string` | `"monitoring"` | no |
| <a name="input_s3_bucket_prefix"></a> [s3\_bucket\_prefix](#input\_s3\_bucket\_prefix) | The aws S3 storage/bucket name prefix to use while generating buckets for tempo and loki | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
