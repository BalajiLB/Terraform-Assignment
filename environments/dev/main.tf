
provider "aws" {
  region = var.aws_region 
}

# VPC Flow Logs Role
data "aws_iam_policy_document" "flow_logs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs_role" {
  name = "${var.env}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role_policy.json
}

# EC2 IAM Role

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.env}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}


#vpc module (2-public subnets)
module "vpc" {
  source               = "../../modules/vpc"
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_a_cidr = var.public_subnet_a_cidr
  public_subnet_b_cidr = var.public_subnet_b_cidr
  availability_zone_a  = var.availability_zone_a
  availability_zone_b  = var.availability_zone_b
  default_route_cidr   = var.default_route_cidr
  aws_region           = var.aws_region
  flow_logs_role_arn   = aws_iam_role.flow_logs_role.arn


}

#sg module  
module "sg" {
  source = "../../modules/sg"
  env    = var.env
  vpc_id = module.vpc.vpc_id

  # Ingress split variables
  ingress_descriptions = var.ingress_descriptions
  ingress_from_ports   = var.ingress_from_ports
  ingress_to_ports     = var.ingress_to_ports
  ingress_cidr_blocks  = var.ingress_cidr_blocks

  # Egress variables
  egress_from_port   = var.egress_from_port
  egress_to_port     = var.egress_to_port
  egress_protocol    = var.egress_protocol
  egress_cidr_blocks = var.egress_cidr_blocks

  # Common tags
  tags = var.tags
}

#ec2 module
module "ec2" {
  source             = "../../modules/ec2"
  env                = var.env
  instance_type      = var.instance_type
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  aws_security_group = module.sg.ec2_sg
  ec2_role_name      = aws_iam_role.ec2_role.name
}


#s3 module
module "s3" {
  source      = "../../modules/s3"
  env         = var.env
  bucket_name = var.bucket_name
  tags        = var.tags
}
