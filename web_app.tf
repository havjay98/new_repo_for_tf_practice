terraform {
  backend "s3" {
    bucket         = "terraform-exercises-tf-state"
    key            = "terraform_exercises/import-bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

resource "aws_instance" "example1" {
  ami                    = "ami-0c614dee691cbbf37"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]



  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, world 2" > index.html
                python3 -m httpd -f -p ${var.server_port} &
                EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_instance" "example2" {
  ami                    = "ami-0c614dee691cbbf37"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]



  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, world 1" > index.html
                python3 -m httpd -f -p ${var.server_port} &
                EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

data "aws_vpc" "default_vpc" {
  id = var.aws_vpc.id
}

data "aws_subnet" "default_subnet" {
  id = var.aws_subnet.id
}

resource "aws_security_group" "terraform_exercises_security_group" {
  name = "terraform-excercise-security-group"
}

resource "aws_security_group_rule" "allow_http_ingress" {
  type              = "ingress"
  security_group_id = var.aws_security_group.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.default_vpc.cidr_block]
  ipv6_cidr_blocks  = [data.aws_vpc.default_vpc.ipv6_cidr_block]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "instances" {
  name     = "tf-example-lb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.test1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.test2.id
  port             = 8080
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

resource "aws_security_group" "alb" {
  name = "aws_alb_security_group"
}

resource "aws_security_group_rule" "alb_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_outbound_rule" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "lb_excercises" {
  name               = "alb_instances"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_route53_zone" "primary" {
  name = "tfexcercises.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "tfexcercisesrecord.com"
  type    = "A"

  alias {
    name                   = aws_lb.lb_excercises.dns_name
    zone_id                = aws_lb.lb_excercises.zone_id
    evaluate_target_health = true
  }
}