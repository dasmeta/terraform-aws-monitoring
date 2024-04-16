terraform {
  required_providers {
    # Dear Tigran, test provider is deprecated and has to be renovated.
    # test = {
    #   source = "terraform.io/builtin/test"
    # }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "tets_topic_for_alarm_actions" {
  name = "tets-topic-for-alarm-actions"
}
