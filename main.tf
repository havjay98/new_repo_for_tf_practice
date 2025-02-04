provider "aws" {
    region = "us-east-1"
}

resource "aws_ec2_instance" "example" {
    ami = "ami-0c614dee691cbbf37"
    instance_type = "t2.micro"
  
}