################
#공급자 정의
################

provider "aws" {
  region = var.aws_region
}

################
#AWS VPC 정의
################

resource "aws_vpc" "main" {
  cidr_block           = var.main_vpc_cidr
  enable_dns_support   = true #기본 VPC에서 DNS 지원을 활성화
  enable_dns_hostnames = true #기본 VPC에서 DNS 호스트 이름을 활성화

  tags = {
    "Name"                                      = var.vpc_name
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

################
#서브넷 정의
################

resource "aws_subnet" "public-subnet-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "Name"                                      = "${var.vpc_name}-public-subnet-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1" #로드밸런싱 사용
  }
}

resource "aws_subnet" "public-subnet-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "Name"                                      = "${var.vpc_name}-public-subnet-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "Name"                                      = "${var.vpc_name}-private-subnet-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "Name"                                      = "${var.vpc_name}-private-subnet-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

################
#공개 서브넷과 인터넷 게이트웨이 연결
################

#인터넷 게이트웨이 구성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

#공개 서브넷에 대한 인터넷 게이트웨이 라우팅 정의 (라우팅 규칙)
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "${var.vpc_name}-public-route"
  }
}

#공개 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public-a-association" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "public-b-association" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.public-route.id
}

################
#사설 서브넷과 라우팅 테이블간 설정 (POD가 EKS 서비스와 통신 (사설 subnet<->Internet Gateway))
#참고 keyword: NAT(네트워크 주소 변환), EIP(Elastic IP address)
################

#NAT Gateway 구성
resource "aws_eip" "nat-a" {
  vpc = true

  tags = {
    "Name" = "${var.vpc_name}-NAT-a"
  }
}

resource "aws_eip" "nat-b" {
  vpc = true

  tags = {
    "Name" = "${var.vpc_name}-NAT-b"
  }
}

resource "aws_nat_gateway" "nat-gw-a" {
  allocation_id = aws_eip.nat-a.id
  subnet_id     = aws_subnet.public-subnet-a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    "Name" = "${var.vpc_name}-NAT-gw-a"
  }
}

resource "aws_nat_gateway" "nat-gw-b" {
  allocation_id = aws_eip.nat-b.id
  subnet_id     = aws_subnet.public-subnet-b.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    "Name" = "${var.vpc_name}-NAT-gw-b"
  }
}

#사설 서브넷에 대한 NAT gateway 라우팅 정의
resource "aws_route_table" "private-route-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-a.id
  }

  tags = {
    "Name" = "${var.vpc_name}-private-route-a"
  }
}

resource "aws_route_table" "private-route-b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-b.id
  }

  tags = {
    "Name" = "${var.vpc_name}-private-route-b"
  }
}

#사설 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private-a-association" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-route-a.id
}

resource "aws_route_table_association" "private-b-association" {
  subnet_id      = aws_subnet.private-subnet-b.id
  route_table_id = aws_route_table.private-route-b.id
}