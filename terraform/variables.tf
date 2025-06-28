variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_name" {
  type    = string
  default = "urlshortener"
}

variable "db_user" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}