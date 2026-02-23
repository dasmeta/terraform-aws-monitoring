variable "name" {
  type        = string
  description = "Name prefix for AWS Config resources"
}

variable "record_all_resources" {
  type        = bool
  default     = true
  description = "Record all supported resource types in AWS Config"
}

variable "include_global_resources" {
  type        = bool
  default     = true
  description = "Include global resources (IAM, etc.) in AWS Config recording"
}

variable "included_resource_types" {
  type        = list(string)
  default     = []
  description = "List of resource types to include when record_all_resources is false. If empty and record_all_resources is false, all resources are excluded."
}

variable "excluded_resource_types" {
  type        = list(string)
  default     = []
  description = "List of resource types to exclude when record_all_resources is true."
}

variable "s3_bucket_name" {
  type        = string
  default     = ""
  description = "S3 bucket name for AWS Config. If empty, a bucket will be created automatically."
}

variable "s3_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Force destroy S3 bucket for Config when deleting the module"
}

variable "delivery_frequency" {
  type        = string
  default     = "TwentyFour_Hours"
  description = "Frequency for Config snapshot delivery. Valid values: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}

variable "rules" {
  type = map(object({
    description = optional(string)
    source = optional(object({
      owner             = string
      source_identifier = string
      source_detail = optional(list(object({
        event_source                = optional(string)
        maximum_execution_frequency = optional(string)
        message_type                = optional(string)
      })))
    }))
    scope = optional(object({
      compliance_resource_types = optional(list(string))
      compliance_resource_id    = optional(string)
      tag_key                   = optional(string)
      tag_value                 = optional(string)
    }))
    input_parameters = optional(string)
    tags             = optional(map(string))
  }))
  default     = {}
  description = "Map of Config rules to create. Key is the rule name. If empty, no rules will be created."
}

variable "create_service_linked_role" {
  type        = bool
  default     = true
  description = "Whether to create the AWS Config service-linked role. Set to false if the role already exists in your account. If set to false and the role doesn't exist, Terraform will fail. If set to true and the role already exists, Terraform will fail with EntityAlreadyExists error - in that case, set this to false and import the existing role: terraform import module.config.aws_iam_service_linked_role.config aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}
