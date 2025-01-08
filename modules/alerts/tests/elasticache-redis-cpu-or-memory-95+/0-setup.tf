terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_sns_topic" "tets_topic_for_alarm_actions" {
  name = "tets-topic-for-alarm-actions"
}
