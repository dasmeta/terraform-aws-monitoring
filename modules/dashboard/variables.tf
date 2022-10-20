variable "name" {
  type = string

  description = "Dashboard name. Should not contain spaces and special chars."
}

variable "defaults" {
  type = any
  ## valid values
  # object({
  #     period    = number
  #     namespace = string
  #     cluster   = string
  #     width     = number
  #     height    = number
  #   }
  # )

  default = {}

  description = "Default values to be supplied to all modules."
}

variable "rows" {
  type = any

  description = "List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets."
}
