provider "aws" {
  region = "us-east-1" # my region
}

# Launch Template using the AMI
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type

  #key_name = "EC2 Tutorial"  # my existing key pair

user_data = filebase64("userdata.sh")

#  security_group_names = [aws_security_group.web_sg.name]
vpc_security_group_ids = [aws_security_group.web_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "AppInstance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for allow HTTP and SSH access
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-http-ssh"
  }
}

# Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = ["subnet-000623f641acd0812", "subnet-099715a3f1d20ffed","subnet-093238a4109c7c384","subnet-0504ee6386d8e3f18","subnet-099a3cfc4e7e1fc42"] # subnet IDs

  enable_deletion_protection = false

  tags = {
    Name = "app-lb"
  }
}

# Target group for the load balancer
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-089257c342f8ec0b5" # VPC ID

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-target-group"
  }
}

# Listener for the load balancer
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = ["subnet-000623f641acd0812", "subnet-099715a3f1d20ffed","subnet-093238a4109c7c384","subnet-0504ee6386d8e3f18","subnet-099a3cfc4e7e1fc42"] # subnet IDs

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "AppInstance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
