###Launch EC2 Instances with Tags
#Find latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2_iam" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
#Find VPC ID
data "aws_vpc" "immersion_day_iam" {
  cidr_block = var.cidr_block
}
#Find subnets
data "aws_subnets" "immersion_day_iam" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.immersion_day_iam.id]
  }
}
#Create EC2 Instances
resource "aws_instance" "web_iam1" {
  ami           = data.aws_ami.amazon_linux_2_iam.id
  instance_type = "t2.micro"
  subnet_id =  tolist(data.aws_subnets.immersion_day_iam.ids)[0]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  key_name = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.immersion_day_web_server.id]
  tags = {
    Name = "prod-instance"
    Env = "prod"
  }
}
resource "aws_instance" "web_iam2" {
  ami           = data.aws_ami.amazon_linux_2_iam.id
  instance_type = "t2.micro"
  subnet_id =  tolist(data.aws_subnets.immersion_day_iam.ids)[0]
  associate_public_ip_address = true
  key_name = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.immersion_day_web_server.id]
  tags = {
    Name = "dev-instance"
    Env = "dev"
  }
}

### Create AWS IAM Identities
#Create Dev Policy
resource "aws_iam_policy" "dev_policy" {
  name        = "DevPolicy"
  path        = "/"
  description = "IAM Policy for Dev Group"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Env": "dev"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Deny",
            "Action": [
                "ec2:DeleteTags",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
#Create Dev Group
resource "aws_iam_group" "dev_group" {
  name = "dev-group"
  path = "/"
}
#Attach Group
resource "aws_iam_policy_attachment" "dev_attach" {
  name       = "dev-attachment"
  groups     = [aws_iam_group.dev_group.name]
  policy_arn = aws_iam_policy.dev_policy.arn
}
#Create User
resource "aws_iam_user" "dev_user" {
  name = "dev-user"
  path = "/"

  tags = {
    tag-key = "tag-value"
  }
}
#Create User Access Key
resource "aws_iam_access_key" "dev_user" {
  user    = aws_iam_user.dev_user.name
}
#Create User Password
resource "aws_iam_user_login_profile" "dev_user" {
  user    = aws_iam_user.dev_user.name
  password_reset_required = false
}
#Add User to group
resource "aws_iam_group_membership" "tdeveam" {
  name = "dev-group-membership"

  users = [
    aws_iam_user.dev_user.name,
  ]

  group = aws_iam_group.dev_group.name
}
#Output details
output "dev_access_key" {
    value = aws_iam_access_key.dev_user.id
}
output "dev_secret_key" {
    value = aws_iam_access_key.dev_user.secret
    sensitive = true
}
output "dev_password" {
    value = aws_iam_user_login_profile.dev_user.password
}

###Assign IAM Role for EC2 Instance and Test the access
#Create bucket
resource "aws_s3_bucket" "immersion_day" {
  bucket_prefix = "immersion-day"
}
#Block public access
resource "aws_s3_bucket_public_access_block" "immersion_day" {
  bucket = aws_s3_bucket.immersion_day.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
#Upload file
resource "aws_s3_object" "example" {
  key                    = "aws-logo-sample.jpg"
  bucket                 = aws_s3_bucket.immersion_day.id
  source                 = "source/aws-logo-sample.jpg"
}
#Create bucket
resource "aws_s3_bucket" "immersion_day2" {
  bucket = "iam-test-${aws_iam_user.dev_user.name}"
}
#Block public access
resource "aws_s3_bucket_public_access_block" "immersion_day2" {
  bucket = aws_s3_bucket.immersion_day2.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
#Upload file
resource "aws_s3_object" "example2" {
  key                    = "aws-logo-sample.jpg"
  bucket                 = aws_s3_bucket.immersion_day2.id
  source                 = "source/aws-logo-sample.jpg"
}
#Create Policy for EC2 role
resource "aws_iam_policy" "ec2_policy" {
  name        = "IAMBucketTestPolicy"
  path        = "/"
  description = "IAM Policy for EC2"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect": "Allow",
        "Resource": ["arn:aws:s3:::*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::iam-test-${aws_iam_user.dev_user.name}/*",
                "arn:aws:s3:::iam-test-${aws_iam_user.dev_user.name}"
            ]
        }
    ]
}
EOF
}
#Create Role
resource "aws_iam_role" "ec2_role" {
  name = "IAMBucketTestRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
  }
EOF
}
#Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}
#Create EC2 Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "IAMBucketTestRole"
  role = aws_iam_role.ec2_role.name
}