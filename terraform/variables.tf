variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "region" {
    description = "Desired Region"
    type = string
    default = "us-east-2"
}
variable "Api_Key" {
  description = "API Key"
  type = string
}
variable "EMAIL" {
  type = string
}

variable "EMAIL_KEY" {
  type = string
}

variable "EMAIL_TO" {
  type = string
}

variable "EMAIL_HOST" {
  type = string
  default = "smtp.gmail.com"  # Optional: Set a default if applicable
}