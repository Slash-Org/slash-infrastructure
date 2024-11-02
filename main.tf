provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create a VPC for the EC2 instance
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group
resource "aws_security_group" "fashion_assistant" {
  name        = "fashion-assistant-sg"
  description = "Security group for Fashion Assistant backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node.js application port"
    from_port   = 3000
    to_port     = 3000
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
    Name = "fashion-assistant-sg"
  }
}

# Create EC2 Instance
resource "aws_instance" "fashion_assistant" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.fashion_assistant.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Update system packages
              apt-get update
              apt-get upgrade -y
              
              # Install Node.js 18
              curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
              apt-get install -y nodejs

              # Install Git
              apt-get install -y git

              # Create app directory with correct permissions
              mkdir -p /home/ubuntu/fashion-assistant
              chown -R ubuntu:ubuntu /home/ubuntu/fashion-assistant
              chmod 755 /home/ubuntu/fashion-assistant

              # Install PM2 globally
              npm install -g pm2
              
              # Set environment variables
              echo "export NODE_ENV=production" >> /home/ubuntu/.bashrc
              echo "export PORT=3000" >> /home/ubuntu/.bashrc
              
              # Ensure ubuntu user owns their home directory
              chown -R ubuntu:ubuntu /home/ubuntu/
              EOF

  tags = {
    Name        = "fashion-assistant-backend"
    Environment = "development"
    Application = "nodejs"
  }
}

# Create a key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "fashion-assistant-key"
  public_key = file(pathexpand("~/.ssh/fashion-assistant.pub"))
}

# Output the public IP
output "fashion_assistant_public_ip" {
  value = aws_instance.fashion_assistant.public_ip
}
