### Create a VPC
#Create VPC
resource "aws_vpc" "immersion_day_lab_2" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-Lab"
  }
}
#Create Internet Gateway
resource "aws_internet_gateway" "immersion_day_lab_2" {}
#Attach Internet Gateway to VPC
resource "aws_internet_gateway_attachment" "immersion_day_lab_2" {
  internet_gateway_id = aws_internet_gateway.immersion_day_lab_2.id
  vpc_id              = aws_vpc.immersion_day_lab_2.id
}
#Setup Internet Routing with default route table
resource "aws_default_route_table" "immersion_day_lab_2" {
  default_route_table_id = aws_vpc.immersion_day_lab_2.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.immersion_day_lab_2.id
  }
}
# Find the region to pick the right availability zone
data "aws_region" "current" {}
#Create Public Subnet in Availability Zone A
resource "aws_subnet" "immersion_day_lab_2a" {
  vpc_id     = aws_vpc.immersion_day_lab_2.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "public Subnet A"
  }
}
### Create additional subnets
#Create Public Subnet in Availability Zone C
resource "aws_subnet" "immersion_day_lab_2c" {
  vpc_id     = aws_vpc.immersion_day_lab_2.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  tags = {
    Name = "public Subnet C"
  }
}
### Create a security group
#Create Security Group
resource "aws_security_group" "webserver_sg" {
  name        = "secuirty group for web servers"
  description = "secuirty group for web servers"
  vpc_id      = aws_vpc.immersion_day_lab_2.id

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
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secuirty group for web servers"
  }
}