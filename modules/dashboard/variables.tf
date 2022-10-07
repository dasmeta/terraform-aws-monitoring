variable "name" {
  type = string

  description = "Dashboard name. Should not contain spaces and special chars."
}

variable "defaults" {
  type = object(
    {
      # period      = number
      # namespace   = string
      # clustername = string
      # width       = number
      # height      = number
    }
  )

  default = {}

  description = "Default values to be supplied to all modules."
}

variable "rows" {
  type = list(list(any))

  description = "List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets."
}
