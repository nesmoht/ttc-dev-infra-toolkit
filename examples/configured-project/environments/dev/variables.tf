variable "workload" {
  description = "Workload name"
  type        = string
  default     = "dataplatform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}
