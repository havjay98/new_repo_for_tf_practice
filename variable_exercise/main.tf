terraform {
  /*backend "s3" {
    bucket         = "terraform-exercises-tf-state"
    key            = "terraform_exercises/import-bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }*/
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  extra_tags = "extra-tag"
}

resource "aws_instance" "instance1" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.name]
  user_data       = <<-EOF
                #!/bin/bash
                echo "Hello, world 1" > index.html
                python3 -m httpd -f -p ${var.server_port} &
                EOF

  user_data_replace_on_change = true


  tags = {
    name       = var.instance_name
    extra_tags = local.extra_tags
  }
}

resource "aws_instance" "instance2" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.name]
  user_data       = <<-EOF
                #!/bin/bash
                echo "Hello, world 1" > index.html
                python3 -m httpd -f -p ${var.server_port} &
                EOF

  user_data_replace_on_change = true


  tags = {
    name       = var.instance_name
    extra_tags = local.extra_tags
  }
}

resource "aws_s3_bucket" "bucket_prefix" {
  bucket_prefix = var.bucket_prefix
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_vpc" "my-vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group" "terraform_exercises_security_group" {
  name = "terraform-excercise-security-group"
}

resource "aws_security_group_rule" "allow_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.terraform_exercises_security_group.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.default_vpc.cidr_block]
  ipv6_cidr_blocks  = [data.aws_vpc.default_vpc.ipv6_cidr_block]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb_excercises.arn

  port = 80

  protocol = "HTTP"

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

resource "aws_lb_target_group_attachment" "instance1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.example1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.example2.id
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
  name               = "alb-instances"
  load_balancer_type = "application"
  subnets            = data.aws_subnet.default_subnet.id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.lb_excercises.dns_name
    zone_id                = aws_lb.lb_excercises.zone_id
    evaluate_target_health = true
  }
}


resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  db_name              = var.db_name
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

}