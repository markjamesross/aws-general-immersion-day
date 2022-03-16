### Create a new key pair section
#Generate a new public and private key
resource "tls_private_key" "this" {
  algorithm = "RSA"
}
#Create a key pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.name}-ImmersionDay"
  public_key = tls_private_key.this.public_key_openssh
}
#Create file for private key
resource "local_sensitive_file" "private_key" {
    content     = tls_private_key.this.private_key_pem
    filename = "${path.module}/${var.name}-ImmersionDay.pem"
}

###Launch a Web Server Instance
#Find latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
#Find VPC ID
data "aws_vpc" "immersion_day" {
  cidr_block = var.cidr_block
}
#Find subnets
data "aws_subnets" "immersion_day" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.immersion_day.id]
  }
}
#Find my public IP address
module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}
#Create Security Group
resource "aws_security_group" "immersion_day_web_server" {
  name        = "Immersion Day-Web Server"
  description = "Immersion Day-Web Server"
  vpc_id      = data.aws_vpc.immersion_day.id

  ingress {
    description      = "SSH inbound from all"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP inbound from My IP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["${module.myip.address}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Immersion Day-Web Server"
  }
}
#Create EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id =  tolist(data.aws_subnets.immersion_day.ids)[0]
  associate_public_ip_address = true
  key_name = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.immersion_day_web_server.id]
  user_data = <<EOF
#! /bin/bash
sudo yum -y install httpd php mysql php-mysql
sudo chkconfig httpd on
sudo systemctl start httpd
if [ ! -f /var/www/html/immersion-day-app.tar.gz ]; then
   cd /var/www/html
   sudo wget https://aws-joozero.s3.ap-northeast-2.amazonaws.com/immersion-day-app.tar.gz
   sudo tar xvfz immersion-day-app.tar.gz
   sudo chown apache:root /var/www/html/rds.conf.php
fi
yum -y update
EOF
  tags = {
    Name = "Web server for custom AMI"
  }
}

output "web_public_dns_name" {
  value = aws_instance.web.public_dns
}