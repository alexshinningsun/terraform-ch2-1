provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

data "aws_vpc" "default" {  // 1 get the default VPC
  default = true
}

data "aws_subnets" "default" { 
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] // 2 get the default VPC ID, ==> then we can get the default VPC subnet
  }
}

# Part : security group

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  # Allow ec2 instance to receive traffic on port 8080
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids # 3 now we can get the default VPC's subnet IDs
  min_size = 2
  max_size = 10

  tag {
    key = "name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

output "name_prefix" {
  value       = aws_autoscaling_group.example.name_prefix
  description = "The name_prefix"
} 