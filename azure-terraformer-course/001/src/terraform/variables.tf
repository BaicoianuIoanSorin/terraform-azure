variable "application_name" {
  type        = string
  description = "The name of the application"
}

variable "environment_name" {
  type        = string
  description = "The name of the environment"

}

variable "location" {
  type        = string
  description = "The azure region in which the resources will be deployed"
}
