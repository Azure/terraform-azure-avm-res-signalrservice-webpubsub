variable "location" {
  type        = string
  default     = "westus3"
  description = "The Azure region for the resource group, virtual network, Web PubSub service, and private endpoint."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags applied to all tag-capable resources in the example, including the module's private endpoint."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable module telemetry. See https://aka.ms/avm/telemetryinfo."
  nullable    = false
}
