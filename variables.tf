variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Local onde o grupo de recursos sera criado"
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefixo que sera anexado ao nome randomico de grupo de recursos"
}

variable "username" {
  type        = string
  description = "O usuario que sera usado para nos conectarmos nas VMs"
  default     = "acmeadmin"
}

variable "number_resources" {
  type        = number
  default     = 2
  description = "Numero de VMs que serao criadas"
}