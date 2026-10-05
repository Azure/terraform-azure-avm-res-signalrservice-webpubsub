variable "location" {
  type        = string
  default     = "westus3"
  description = "The Azure region for the example."
  nullable    = false
}

variable "resource_types" {
  type = object({
    resources_resource_groups = optional(string, "Microsoft.Resources/resourceGroups@2024-11-01")
  })
  default     = {}
  description = "AzAPI resource types. `resources_resource_groups` is the resource group API version."
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    resources_resource_groups = optional(list(string), [])
  })
  default     = {}
  description = "Body-relative dot-notation paths to ignore on the resource group. Changes take effect only after apply; ignored configuration is not sent to Azure."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Optional resource group retry configuration: error message patterns, initial interval seconds, and maximum interval seconds."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional resource group create, read, update, and delete timeouts, as Go duration strings."
}
