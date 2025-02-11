terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami                    = "ami-0c614dee691cbbf37"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]



  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, world" > index.html
                python3 -m httpd -f -p ${var.server_port} &
                EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = var.security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

