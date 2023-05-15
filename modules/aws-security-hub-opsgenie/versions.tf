terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }

    # TODO: seems it was supposed to use this provider to create opsgenie topic but it is not used anymore, so commented out, please check if this can be used or removed
    # opsgenie = {
    #   source  = "opsgenie/opsgenie"
    #   version = ">= 0.6.20"
    # }
  }
}
