variable "name" {
  type = string
}

variable "secret_id" {
  type = string  
  default = "my-db-secret"
}

variable "db_name" { 
    type = string 
    default = "appdb" 
    }

variable "username" { 
    type = string 
    default = "appuser" 
    }

variable "password" { 
    type = string 
    }  

variable "allocated_storage" { 
    type = number 
    default = 20 
    }

variable "instance_class" { 
    type = string 
    default = "db.t3.micro" 
    }

variable "engine" { 
    type = string 
    default = "mysql" 
    }

variable "engine_version" { 
    type = string 
    default = "8.0" 
    }

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "multi_az" { 
    type = bool 
    default = false 
    }

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "db_subnet_ids" { 
    type = list(string) 
    }

variable "vpc_security_group_ids" { 
    type = list(string) 
    }

variable "publicly_accessible" {
    type    = bool
    default = false
}  

variable "storage_encrypted" {
    type    = bool
    default = true
} 

variable "auto_minor_version_upgrade" {
    type    = bool
    default = true
} 

variable "tags" { 
    type = map(string) 
    default = {} 
    }
