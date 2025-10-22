terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "default" # Asegúrate de usar el perfil configurado en ~/.aws/credentials
}

# -------------------- VPC --------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -------------------- Subnet --------------------
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

# -------------------- Internet Gateway --------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# -------------------- Route Table --------------------
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

# -------------------- Route Table Association --------------------
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}

# -------------------- Security Group --------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# -------------------- Random ID para el bucket --------------------
resource "random_id" "bucket_id" {
  byte_length = 4
}

# -------------------- S3 Bucket --------------------
resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.project_name}-photo-upload-${random_id.bucket_id.hex}-misuki"
  force_destroy = true

  # Se elimina object_lock_configuration

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

# -------------------- EC2 Instance --------------------
resource "aws_instance" "web_server" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  # Script para instalar Flask y conectarse a S3
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              pip3 install flask boto3
              cd /home/ec2-user
              cat <<EOL > app.py
              from flask import Flask, request
              import boto3, os

              app = Flask(__name__)
              s3 = boto3.client('s3')
              BUCKET = '${aws_s3_bucket.app_bucket.bucket}'

              @app.route('/')
              def home():
                  return '''
                  <h2>Upload a photo to S3</h2>
                  <form action="/upload" method="post" enctype="multipart/form-data">
                      <input type="file" name="file">
                      <input type="submit" value="Upload">
                  </form>
                  '''

              @app.route('/upload', methods=['POST'])
              def upload():
                  f = request.files['file']
                  s3.upload_fileobj(f, BUCKET, f.filename)
                  return f"Uploaded {f.filename} to S3 bucket: {BUCKET}"

              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=80)
              EOL
              python3 app.py &
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
