terraform {
  backend "s3" {
    bucket = "data-eks-states"
    key    = "terraform-env"
    region = "ap-northeast-3"

    profile                 = "de_admin"
    shared_credentials_file = "~/.aws/credentials"
  }
}

provider "aws" {
  region  = "ap-northeast-3"
  profile = "de_admin"
}

#다른 모듈들에서도 공통적으로 사용할 값
locals {
  name              = "tumblbug-data-infra"
  region            = "ap-northeast-3"
  availability_zone = "ap-northeast-3a"
  cluster_name      = "tumblbug-datahub"
  tags = {
    Owner       = "de"
    Environment = "dev"
  }
}

#네트워크 모듈 값
module "aws-network" {
  source = "git@github.com-private:Gyeong-Hyeon/tumblbug-datahub.git//infra/network"

  name                  = local.name
  vpc_name              = "data_eks_vpc"
  cluster_name          = local.cluster_name
  aws_region            = local.region
  main_vpc_cidr         = "10.10.0.0/16"
  public_subnet_a_cidr  = "10.10.0.0/18"
  public_subnet_b_cidr  = "10.10.64.0/18"
  private_subnet_a_cidr = "10.10.128.0/18"
  private_subnet_b_cidr = "10.10.192.0/18"
  tags                  = local.tags
}

#eks 설정 값
module "aws-kubernetes-cluster" {
  source = "git@github.com-private:Gyeong-Hyeon/tumblbug-datahub.git//infra/eks"

  env_name           = local.name
  aws_region         = local.region
  cluster_name       = local.cluster_name
  cluster_role_name  = "datahub_cluster"
  vpc_id             = module.aws-network.vpc_id
  cluster_subnet_ids = module.aws-network.subnet_ids

  node_role_name           = "datahub_node"
  nodegroup_subnet_ids     = module.aws-network.private_subnet_ids
  nodegroup_disk_size      = "20"
  nodegroup_instance_types = ["t3.medium"]
  nodegroup_desired_size   = 3
  nodegroup_min_size       = 2
  nodegroup_max_size       = 3
  tags                     = local.tags
}