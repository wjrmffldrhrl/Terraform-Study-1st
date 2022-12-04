# Getting Started With Terraform
이 장에서 다룰 내용

- AWS 계정 설정
- 테라폼 설치
- 단일 서버 배포
- 단일 웹 서버 배포
- 구성 가능한 웹 서버 배포
- 웹 서버 클러스터 배포
- 로드 밸런서 배포
- 정리

# 1: AWS 계정 설정

AWS (*[https://aws.amazon.com](https://aws.amazon.com/))* 에서 계정 생성 후 제한된 권한을 가진 다른 사용자 계정을 만든다.

다른 사용자 만들기

1. IAM 콘솔 → 사용자 → 사용자추가
2. AWS 액세스 유형 선택 : ‘프로그래밍 방식 엑세스’ 체크
3. 권한 설정 : ‘기존 정책 직접 연결’
    1. [AmazonEC2FullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAmazonEC2FullAccess)
    2. [AmazonS3FullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAmazonS3FullAccess)
    3. [AmazonDynamoDBFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAmazonDynamoDBFullAccess)
    4. [AmazonRDSFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAmazonRDSFullAccess)
    5. [CloudWatchFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FCloudWatchFullAccess)
    6. [IAMFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FIAMFullAccess)
    7. [AutoScalingFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAutoScalingFullAccess)
    8.  or AdministratorAccess
4. 키 보관
    1. 액세스키 
    2. 비밀 액세스 키 

# 2: 테라폼 설치

## 테라폼 바이너리 설치

```bash
brew install terraform
```

## 자격증명

- 환경변수

```bash
$ export AWS_ACCESS_KEY_ID=(액세스 키 ID)
$ export AWS_SECRET_ACCESS_KEY=(비밀 액세스 키)
```

- 자격증명 파일 사용 *$HOME/.aws/credentials*

```bash
[default]
aws_access_key_id=(액세스 키 ID)
aws_secret_access_key=(비밀 액세스 키)
```

# 3: 단일 서버 배포

빈 디렉토리에 [main.tf](terraform/main.tf) 파일을 생성하고 공급자 구성 및 리소스 정의 후 `terraform init` 

- 공급자 구성

```
provider "aws" {
  region = "us-east-2"
}
```

- 리소스 정의

```
resource "<PROVIDER>_<TYPE>" "<NAME>" {
  [CONFIG ...]
}
```

- main.tf

```
provider "aws" {
  region = "us-east-2"
}
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}
```

- terraform init

```bash
ui-MacBook-Pro:terraform aa$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v4.45.0...
- Installed hashicorp/aws v4.45.0 (signed by HashiCorp)
...
```

- terraform plan

```
ui-MacBook-Pro:terraform aa$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.example will be created
  + resource "aws_instance" "example" {
      + ami                                  = "ami-0fb653ca2d3203ac1"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t2.micro"
      + ipv6_address_count                   = (known after apply)
      ...
```

- terraform apply

```
ui-MacBook-Pro:terraform aa$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.example will be created
  + resource "aws_instance" "example" {
      + ami                                  = "ami-0fb653ca2d3203ac1"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
    ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_instance.example: Creating...
aws_instance.example: Still creating... [10s elapsed]
aws_instance.example: Still creating... [20s elapsed]
aws_instance.example: Creation complete after 25s [id=i-026032b2636d4d398]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

![Untitled](asset/chapter_2_1.png)

# 4: 단일 웹서버 배포

HTTP 요청에 응답할 수 있는 단일 웹 서버 배포


- 기본 우분투 18.04 AMI 에 user_data 인수를 설정하여 busybox 실행한다

```
resource "aws_instance" "example" {
  ami                    = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}
```

- 보안 그룹 생성

이 때, 8080포트에 대해 인바운드 트래픽을 허용시키기 위한 보안 그룹을 생성 하고 보안 그룹 리소스 속성값을 ec2 인스턴스에서 참조한다.

```bash
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- ec2 인스턴스에 vpc id 참조 적용

리소스 참조를 위한 표현식은 `<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>` 이고 위에서 생성한 보안 그룹 인스턴스의 id는 `aws_security_group.instance.id` 와 같이 표현할 수 있다.

```bash
resource "aws_instance" "example" {
  ami                    = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}
```

- 실행

```bash
terraform apply
```

### 1) instance replace

user_data 는 인스턴스 실행시 최초 1번만 실행되므로 user_data 를 변경할 경우 기존 인스턴스를 새로운 인스턴스로 대체한다 → 멱등성

테라폼 apply 로그에서 `aws_instance.example must be replaced`  를 확인할 수 있다

```bash
# aws_instance.example must be replaced
-/+ resource "aws_instance" "example" {
      ~ arn                                  = "arn:aws:ec2:us-east-2:861532850823:instance/i-026032b2636d4d398" -> (known after apply)
      ~ associate_public_ip_address          = true -> (known after apply)
```

### 2) 종속성

하나의 리소스에서 다른 리소스를 참조로 추가하면 내재된 종속성이 작성된다. 위의 예에서 ec2 인스턴스는 보안그룹 id를 참조하므로 보안그룹 생성 이후 ec2를 생성해야 한다. 테라폼은 선언형 언어이므로 코드 작성 순서와 관계 없이 테라폼이 알아서 종속성 그래프를 작성하여 가장 효율적인 형태로 리소스를 생성한다. 

![Untitled](asset/chapter_2_2.png)

테라폼 종속성은 `terraform graph` 명령어를 통해 확인할 수 있다. 

```bash
ui-MacBook-Pro:terraform aa$ terraform graph
digraph {
        compound = "true"
        newrank = "true"
        subgraph "root" {
                "[root] aws_instance.example (expand)" [label = "aws_instance.example", shape = "box"]
                "[root] aws_security_group.instance (expand)" [label = "aws_security_group.instance", shape = "box"]
                "[root] provider[\"registry.terraform.io/hashicorp/aws\"]" [label = "provider[\"registry.terraform.io/hashicorp/aws\"]", shape = "diamond"]
                "[root] aws_instance.example (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                "[root] aws_security_group.instance (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_instance.example (expand)"
                "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_security_group.instance (expand)"
                "[root] root" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)"
        }
}
```

# 5: 구성 가능한 웹서버 배포

- 입력 변수 선언

```bash
variable "name" {
  description = "설명"
  type        = <데이터 타입: number, string, list, bool, map, object>
  default     = <변수에 값을 전달하지 않았을때 기본 값>
}
```

```bash
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}
```

- 변수 값 전달 방법
    - 환경 변수
        - `export TF_VAR_<variable_name> = <value>`
    - 명령 줄
        - -var 옵션 사용
        - `terraform plan -var “<variable_name>=<value>”`
- 변수 참조 `var.<VARIABLE_NAME>`
    - user_data 와 같은 스크립트에서 변수 참조시 `"${...}"` 중괄호 안에서 참조

```bash
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- 출력 변수 정의

```bash
output "<NAME>" {
  value = <VALUE>
  [CONFIG ...]
}
```

- 인스턴스 퍼블릭 ip 출력

```bash
output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}
```

```bash
terraform apply
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

public_ip = "18.221.24.208"
```
