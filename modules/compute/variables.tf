variable "name" {
  type    = string
  default = "web-app"
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" { type = list(string) } # for ASG

variable "ami" { type = string } # choose region AMI (Amazon Linux 2)

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}


variable "user_data" {
  description = "User data script for EC2"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl enable nginx
    echo "<html><body><h1>Hello from $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h1></body></html>" > /usr/share/nginx/html/index.html
    systemctl start nginx
  EOF
}