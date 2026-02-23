terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      version               = "~> 5.0"
      configuration_aliases = [aws, aws.virginia]
    }
  }
}
