variable "location" {
  type        = string
  default     = "westus3"
  description = "The Azure region for the resource group, identity, and Web PubSub service."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional tags applied to all tag-capable resources."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable module telemetry. See https://aka.ms/avm/telemetryinfo."
  nullable    = false
}
