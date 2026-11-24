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
  name = "default"
}

run "preserve_existing_exclusion_recorder" {
  command = plan

  variables {
    create_service_linked_role = false
    include_global_resources   = false
    excluded_resource_types    = ["AWS::IAM::Policy", "AWS::IAM::User", "AWS::IAM::Role", "AWS::IAM::Group"]
    s3_bucket_name             = "example-existing-config-bucket"
    delivery_frequency         = ""
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported == false
    error_message = "Exclusion recording must set all_supported=false."
  }
  assert {
    condition     = try(aws_config_configuration_recorder.this.recording_group[0].recording_strategy[0].use_only, "") == "EXCLUSION_BY_RESOURCE_TYPES"
    error_message = "Exclusions require the explicit exclusion strategy."
  }
  assert {
    condition     = data.aws_iam_role.config_service_linked_role[0].name == "AWSServiceRoleForConfig"
    error_message = "IAM GetRole requires a role name without its path."
  }
  assert {
    condition     = length(aws_config_delivery_channel.this.snapshot_delivery_properties) == 0
    error_message = "An empty delivery frequency must preserve an unscheduled channel."
  }
  assert {
    condition     = length(aws_s3_bucket.config) == 0 && length(aws_iam_service_linked_role.config) == 0
    error_message = "Adoption must reuse the bucket and service-linked role."
  }
}

run "preserve_new_setup_defaults" {
  command = plan

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported
    error_message = "New setups must continue to record all supported resources."
  }
  assert {
    condition     = aws_config_delivery_channel.this.snapshot_delivery_properties[0].delivery_frequency == "TwentyFour_Hours"
    error_message = "New setups must keep daily snapshot delivery."
  }
}

run "preserve_inclusion_recording" {
  command = plan

  variables {
    record_all_resources     = false
    include_global_resources = false
    included_resource_types  = ["AWS::EC2::Instance"]
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].recording_strategy[0].use_only == "INCLUSION_BY_RESOURCE_TYPES"
    error_message = "Explicit inclusion recording must continue to work."
  }
}
