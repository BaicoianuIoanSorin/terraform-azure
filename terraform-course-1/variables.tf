# You need to create your own terraform.tfvars file with the following content:

variable "source_address_prefix" {
  description = "The source address prefix for the security rule"
}

variable "private_key_location" {
  description = "Location of private key"
}

variable "public_key_location" {
  description = "Location of public key"
}

variable "host_os" {
  description = "The OS of the host"
  type        = string
}