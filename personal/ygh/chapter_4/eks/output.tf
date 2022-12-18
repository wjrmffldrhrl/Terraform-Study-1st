#생성된 클러스터의 id
output "eks_cluster_id" {
  value = aws_eks_cluster.datahub-cluster.id
}

#생성된 클러스터의 이름
output "eks_cluster_name" {
  value = aws_eks_cluster.datahub-cluster.name
}

#생성된 클러스터의 인증서
output "eks_cluster_certificate_data" {
  value = aws_eks_cluster.datahub-cluster.certificate_authority.0.data
}

#생성된 클러스터의 endpoint
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.datahub-cluster.endpoint
}

#생성된 클러스터의 노드 그룹 id
output "eks_cluster_nodegroup_id" {
  value = aws_eks_node_group.node-group.id
}

#생성된 클러스터의 보안 그룹 id
output "eks_cluster_security_group_id" {
  value = aws_security_group.cluster.id
}