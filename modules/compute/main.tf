# ALB security group
resource "aws_security_group" "alb_sg" {
  name = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  ingress { 
    from_port = 80 
    to_port = 80 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = var.tags
}

# app instances security group
resource "aws_security_group" "app_sg" {
  name = "${var.name}-app-sg"
  vpc_id = var.vpc_id
  # allow HTTP from ALB
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = var.tags
}

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
  tags = var.tags
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = "80"
  }
  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  network_interfaces {
    security_groups = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(var.user_data)

  tag_specifications { 
    resource_type = "instance" 
    tags = var.tags 
    }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${var.name}-asg"
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_subnets
  
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  lifecycle { 
    create_before_destroy = true 
   }

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  } 
}

# Target Tracking scaling policy: keep avg CPU at 50%
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "${var.name}-scale-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

output "alb_dns" { value = aws_lb.alb.dns_name }
output "tg_arn" { value = aws_lb_target_group.tg.arn }
output "asg_name" { value = aws_autoscaling_group.asg.name }
