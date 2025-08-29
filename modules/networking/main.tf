# provider "aws" {}

resource "aws_vpc" "web_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge({ "Name" = "${var.tags.Name}-vpc" }, var.tags)
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.web_app_vpc.id
  cidr_block              = each.value
  availability_zone       = element(var.azs, tonumber(each.key))
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.tags.Name}-public-${each.key}" }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = each.value
  availability_zone = element(var.azs, tonumber(each.key))
  tags              = { Name = "${var.tags.Name}-private-${each.key}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.web_app_vpc.id
  tags   = { Name = "${var.tags.Name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.web_app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.tags.Name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways (one per public subnet)
resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id
  tags          = { Name = "${var.tags.Name}-nat-${each.key}" }
}

# Private route tables (each private subnet routes to corresponding NAT)
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.web_app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = { Name = "${var.tags.Name}-private-rt-${each.key}" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Security groups
resource "aws_security_group" "web_sg" {
  name   = "${var.tags.Name}-web-sg"
  vpc_id = aws_vpc.web_app_vpc.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.tags.Name}-web-sg" }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.tags.Name}-db-sg"
  vpc_id = aws_vpc.web_app_vpc.id

  ingress {
    description     = "MySQL from web"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # allow web SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tags.Name}-db-sg" }
}

output "vpc_id" {
  value = aws_vpc.web_app_vpc.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : s.id]
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}
