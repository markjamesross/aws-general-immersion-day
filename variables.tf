variable "deployment_tool" {
  type        = string
  default     = "terraform"
  description = "Tool used to deploy code"
}
variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "aws-general-immersion-day"
}
variable "repository_name" {
  description = "Name of the GitHub Repository."
  type        = string
  default     = "aws-general-immersion-day"
}
variable "name" {
  description = "Name of the person doing the immersion day"
  type        = string
}
variable "cidr_block" {
  description = "CIDR block of the VPC being used in the immersion day"
  type        = string
  default     = "172.31.0.0/16"
}