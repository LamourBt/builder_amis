provider "aws" { 
  region                  = "us-east-1"
  shared_credentials_file = "./secrets/credentials"
}

# instance security groups 
resource "aws_security_group" "p_live_sg" {
  name = "p-live-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.p_live_elb_sg.id]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.p_live_elb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# launch configuration for any ec2s 
resource "aws_launch_configuration" "p_live_instance_l_c" {
  image_id        = "ami-026c8acd92718196b"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.p_live_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

# elb security group 
resource "aws_security_group" "p_live_elb_sg" {
  name = "p-live-elb-sg" 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_availability_zones" "all" {}


# load balancer 
resource "aws_elb" "p_live_elb" {
  name               = "p-live-elb"
  availability_zones = data.aws_availability_zones.all.names

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
}

# auto scaling group 
resource "aws_autoscaling_group" "p_live_asg" {
  launch_configuration = aws_launch_configuration.p_live_instance_l_c.id
  availability_zones   = data.aws_availability_zones.all.names
  name = "p-live-asg" 

  min_size = 2
  max_size = 4

  load_balancers    = [aws_elb.p_live_elb.name]
  health_check_type = "ELB"


  tag {
    key                 = "Name"
    value               = "p-live-server-asg"
    propagate_at_launch = true
  }
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraf-state-bucket"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraf-locks-manager"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraf-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    profile                 = "default"
    shared_credentials_file = "./secrets/credentials"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraf-locks-manager"
    encrypt        = true
  }
}

