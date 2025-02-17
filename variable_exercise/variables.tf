variable "instance_name" {
  description = "name of ec2 instance"
  type        = string
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-0c614dee691cbbf37"

}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_name" {
  description = "RDS DB name"
  type        = string
  default     = "tf-exercise-db"
}

variable "db_username" {
  description = "username for rds db"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "password for rds db"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "aws global region"
  type        = string
  default     = "us-east-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "my-app-bucket"
}

variable "domain" {
  description = "name of domain"
  type        = string
  default     = "tfexcercisesrecord.com"
}