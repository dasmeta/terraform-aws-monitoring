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
