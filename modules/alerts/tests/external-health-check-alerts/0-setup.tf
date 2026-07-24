terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.81"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "tets_topic_for_alarm_actions" {
  name = "tets-topic-for-alarm-actions"
}
