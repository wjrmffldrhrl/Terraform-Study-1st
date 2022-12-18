#가용영역 2개, 각 가용영역별로 공개 subnet 1개, 비공개 subnet 1개 = 총 4개의 subnet

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [
    aws_subnet.public-subnet-a.id,
    aws_subnet.public-subnet-b.id,
    aws_subnet.private-subnet-a.id,
    aws_subnet.private-subnet-b.id
  ]
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public-subnet-a.id,
    aws_subnet.public-subnet-b.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private-subnet-a.id,
    aws_subnet.private-subnet-b.id
  ]
}