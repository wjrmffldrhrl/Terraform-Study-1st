provider "aws" {
  region = var.aws_region
}

###############
#클러스터
###############

#클러스터 서비스의 역할, permission
resource "aws_iam_role" "cluster" {
  name = var.cluster_role_name

  assume_role_policy = <<POLICY
  {
      "Version": "2012-10-17",
      "Statement": [
          {
          "Effect": "Allow",
          "Principal": {
              "Service": "eks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
          }
      ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

#클러스터에 대한 네트워크 보안 정책
resource "aws_security_group" "cluster" {
  name   = var.cluster_name
  vpc_id = var.vpc_id

  ingress {
    #보안그룹 내 인바운드 트래픽
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = var.tags
}

#클러스터 정의 (앞에서 정의한 정책, 보안그룹, 네트워크와 연결)
resource "aws_eks_cluster" "datahub-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]
    subnet_ids         = var.cluster_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy
  ]

  tags = var.tags
}

###############
#노드
###############

resource "aws_iam_role" "node" {
  name = var.node_role_name

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

#노드 그룹 정의
resource "aws_eks_node_group" "node-group" {
  cluster_name    = aws_eks_cluster.datahub-cluster.name
  node_group_name = "${var.cluster_name}-nodegroup"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.nodegroup_subnet_ids

  scaling_config {
    desired_size = var.nodegroup_desired_size
    max_size     = var.nodegroup_max_size
    min_size     = var.nodegroup_min_size
  }

  disk_size      = var.nodegroup_disk_size
  instance_types = var.nodegroup_instance_types

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = var.tags
}

#쿠버네티스 커맨드라인도구(kubectl)과의 연결
resource "local_file" "kubeconfig" {
  content  = <<KUBECONFIG
  apiVersion: v1
  clusters:
  - cluster:
      certificate-authority-data: ${aws_eks_cluster.datahub-cluster.certificate_authority.0.data}
      server: ${aws_eks_cluster.datahub-cluster.endpoint}
    name: ${aws_eks_cluster.datahub-cluster.arn}
  contexts:
  - context:
      cluster: ${aws_eks_cluster.datahub-cluster.arn}
      user: ${aws_eks_cluster.datahub-cluster.arn}
    name: ${aws_eks_cluster.datahub-cluster.arn}
  current-context: ${aws_eks_cluster.datahub-cluster.arn}
  kind: Config
  preferences: {}
  users:
  - name: ${aws_eks_cluster.datahub-cluster.arn}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1alpha1
        command: aws-iam-authenticator
        args:
          - "token"
          - "-i"
          - "${aws_eks_cluster.datahub-cluster.name}"
  KUBECONFIG
  
  filename = "kubeconfig"
}