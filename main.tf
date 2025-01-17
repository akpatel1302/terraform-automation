# Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# Security Group for SSH and HTTP Access
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (adjust for security)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# New Virtual Machine Configuration
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Example Amazon Linux AMI
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

  # Install dependencies and configure services on new VMs
  user_data = <<-EOT
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras enable nginx1
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOT

  tags = {
    Name = "web-instance"
  }
}

# Update Existing Virtual Machines
resource "null_resource" "update_existing" {
  for_each = toset([
    "i-0abcd1234efgh5678", # Replace with actual instance IDs
    "i-0wxyz1234mnop5678"  # Add more instance IDs as needed
  ])

  triggers = {
    instance_id = each.value
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"                     # Replace with the username for your VMs
    private_key = file("~/.ssh/id_rsa")          # Path to your private key
    host        = "your_instance_public_ip"      # Replace with the public IP of your instance
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable nginx1",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }
}

# Output Public IPs of New Instances
output "instance_ips" {
  value = aws_instance.web.public_ip
}
