variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "asg_name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "cpu_alarm_threshold" {
  type    = number
  default = 70
}