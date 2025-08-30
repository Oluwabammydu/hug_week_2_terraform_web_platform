# Web Application Infrastructure with Terraform

This project provisions a **web application infrastructure on AWS** using Terraform.  
It supports multiple environments (`dev`, `prod`) and uses a modular design for networking, database, application and monitoring layers.

---

## 🚀 Features
- **Modular Infrastructure**
  - `compute` module → EC2-based, ALB, ASG  
  - `database` module → Amazon RDS (PostgreSQL/MySQL)
  - `networking` module → VPC, subnets, security groups
  - `monitoring` module → CloudWatch, SNS
  
  
- **Secrets Management** with AWS Secrets Manager (for DB credentials)
- **Environment separation** (`dev` and `prod`) with independent variable sets
- **Local backend** (Terraform state stored locally by default, can be extended to S3/DynamoDB later)
- **Outputs** for quickly accessing resources (e.g., web server address, DB endpoint)

---

## 📂 Project Structure
```markdown
terraform-web-platform/

├── environments/

│   ├── dev/

│   │   ├── main.tf

│   │   ├── terraform.tfvars

│   │   └── outputs.tf

│   └── prod/

│       ├── main.tf

│       ├── terraform.tfvars

│       └── outputs.tf

├── modules/

│   ├── networking/

│   │   ├── main.tf

│   │   ├── variables.tf

│   ├── compute/

│   │   ├── main.tf

│   │   ├── variables.tf

│   ├── database/

│   │   ├── main.tf

│   │   ├── variables.tf

│   ├── monitoring/

│   │   ├── main.tf

│   │   ├── variables.tf

├── README.md

└── .gitignore
```


## ⚙️ Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) 
- AWS CLI configured with appropriate credentials (`aws configure`)
- AWS Secrets Manager secret for DB credentials


## 🛠️ Usage

### 1. Clone the repository
```bash
git clone https://github.com/Oluwabammydu/hug_week_2_terraform_web_platform.git
```
#### Development:
```bash
cd envs/dev
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Validate configuration
```bash
terraform validate
```

### 4. Plan and Apply
```bash
terraform plan
terraform apply
```

### 5. Access Outputs
After apply, Terraform will show outputs.
You can also run:
```bash
terraform output
```

#### Production:
```bash
cd envs/prod
```
Repeat the same workflow for prod.

*Each environment uses its own terraform.tfvars and Secrets Manager entry.*

## 🔑 Secrets Handling
- Database credentials are not hardcoded.
- Terraform fetches them dynamically from AWS Secrets Manager using:
```hcl
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "dev/db-credentials"
}
```
- Never commit real secrets to Git.


## 📌 Notes
- Default setup uses local state (terraform.tfstate inside env folder).
 To switch to S3/DynamoDB backend, update the backend "s3" block in main.tf.
- Web server accessibility depends on networking:
  - If deployed in a public subnet → use EC2 Public IP/DNS
  - If private subnet only → use an ALB or Bastion host


## 🧹 Cleanup
```bash
terraform destroy
```