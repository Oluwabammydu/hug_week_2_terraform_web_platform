variable "name" {
  type = string
  default = "my-web-app"
}

variable "db_secret_id" {
  description = "The ARN or name of the Secrets Manager secret storing DB credentials"
  type        = string
}

variable "alert_email" {
  type = string  
}

