mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "eu-central-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  name                                   = "example-security-hub"
  enable_security_hub                    = false
  enable_security_hub_finding_aggregator = false
  enabled_standards                      = []
  inspector                              = { enabled = false }
  guardduty                              = { enabled = false }
  macie                                  = { enabled = false }
}

run "adopt_default_config_without_renaming_security_hub" {
  command = plan

  variables {
    config = {
      enabled                    = true
      name                       = "default"
      create_service_linked_role = false
      include_global_resources   = false
      excluded_resource_types    = ["AWS::IAM::Policy", "AWS::IAM::User", "AWS::IAM::Role", "AWS::IAM::Group"]
      s3_bucket_name             = "example-existing-config-bucket"
      delivery_frequency         = ""
    }
  }

  assert {
    condition     = module.config[0].configuration_recorder_name == "default" && module.config[0].delivery_channel_name == "default"
    error_message = "The existing Config resource names must be independent of the Security Hub name."
  }
  assert {
    condition     = var.name == "example-security-hub"
    error_message = "Adopting Config must preserve the Security Hub name."
  }
}

run "default_config_name_stays_compatible" {
  command = plan

  variables {
    config = {
      enabled                    = true
      create_service_linked_role = false
      s3_bucket_name             = "example-existing-config-bucket"
    }
  }

  assert {
    condition     = module.config[0].configuration_recorder_name == "example-security-hub" && module.config[0].delivery_channel_name == "example-security-hub"
    error_message = "Omitting config.name must retain the existing naming default."
  }
}
