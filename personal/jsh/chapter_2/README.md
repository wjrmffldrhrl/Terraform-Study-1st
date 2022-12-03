# Setting up your AWS account  

root user를 그대로 사용하는 것은 좋지 않다.
- IAM에서 유저를 생성해서 사용할 것
    - AdministratorAccess 권한 추가

> 해당 책의 예시들은 모두 Default VPC 내부에서 진행된다.  
> AWS의 모든 리소스는 VPC 내부에 배포되고 특정 VPC를 명시하지 않으면 Default VPC에 배포된다.


# Installing Terraform
OS의 package manager를 사용하는게 가장 쉽다.  

mac에서는 Homebrew  
```
$ brew tap hashicorp/tap
$ brew install hashicorp/tap/terraform
```

OR  

[Terraform home page](https://www.terraform.io/)  

Terraform을 생성한 AWS 계정으로 사용 가능하게 하려면 AWS credential을 환경변수로 export 해야 한다.  

```
$ export AWS_ACCESS_KEY_ID=(your access key id)
$ export AWS_SECRET_ACCESS_KEY=(your secret access key)
```  

또는 `$HOME/.aws/credentials` 경로에 crednetial file을 생성해도 된다.  
- `aws configure` 명령어로 생성 가능  


# Deploying a Single Server

HCL로 작성된 .tf 확장자 파일을 생성하여 인프라에 대해 작성하면 된다.  

먼저 어떤 provider를 사용할지 정의한다.

```
# AWS provider 사용
## us-east-2 리전 사용
provider "aws" {
  region = "us-east-2"
}
```
AWS는 여러 지역으로 나눠져있고 각 지역은 Availability Zone이라는 독립된 데이터센터로 나눠져있다.
- `us-east-2a`
- `us-east-2b`


provider가 생성할 수 있는 resource의 종류는 다양하며 일반적인 형태는 아래와 같다.
```
resource "<PROVIDER>_<TYPE>" "<NAME>" {
  [CONFIG ...]
}

```
- PROVIDER: 사용하고자 하는 provider 이름 (e.g. `aws`)
- TYPE: 생성하고자 하는 resource 이름 (e.g. `instance`)
- NAME: resource identifier (e.g. `my_instance`)
- CONFIG: 1개 이상의 resource arguments


위 형식대로 aws EC2 instance를 생성한다고 하면 아래와 같다.
```
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}
```

- ami: EC2 instance를 실행하기 위한 Amazon Machine Image
    - [market place](https://aws.amazon.com/marketplace/search/results?searchTerms=ami)
- instance_type: 실행할 EC2 instance type
    - [EC2 instance types](https://aws.amazon.com/ko/ec2/instance-types/)


> Terraform은 다양한 provider를 제공하고, 이들이 제공하는 모든 resource를 기억할 수 없다.
> 그러므로, 필요할 때 마다 [Terraform 공식 문서](https://registry.terraform.io/browse/providers)를 참고하자

`main.tf` 파일을 생성했으면 `terraform init` command를 수행하자 
```
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using hashicorp/aws v4.19.0 from the shared cache directory

Terraform has been successfully initialized!
```

Terraform을 처음 실행할 때는 어떤 provider를 사용할 것인지 지정하고 provider를 위한 코드를 다운로드 해야한다. 
- 기본 설정으로는 `.terraform` 폴더에 provider 코드가 다운로드된다.  
    - `.terraform.lock.hcl`

Provider가 코드를 다운로드하면 `terraform plan` 명령어를 실행한다.  

```
$ terraform plan

(...)

Terraform will perform the following actions:

  # aws_instance.example will be created
  + resource "aws_instance" "example" {
      + ami                          = "ami-0fb653ca2d3203ac1"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = (known after apply)
      (...)
  }

Plan: 1 to add, 0 to change, 0 to destroy.

```

`plan` 명령어는 Terraform이 변경 사항을 적용하기 전에 어떤 작업을 수행하는지 확인할 수 있다.  
- `diff` 명령어와 비슷하다.  
    - `+`: Add
    - `-`: Delete
    - `~`: Modify


Terraform plan을 확인 후 실제로 instance를 생성하기 위해서는 `terraform apply` 명령어를 수행한다.

```
$ terraform apply

(...)

Terraform will perform the following actions:

  # aws_instance.example will be created
  + resource "aws_instance" "example" {
      + ami                          = "ami-0fb653ca2d3203ac1"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = (known after apply)
      (...)
  }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:

```

생성한 instance에 tag를 추가하는 등 기존에 생성한 리소스에 변경사항을 적용하면 Terraform은 변경사항에 대해 추적할 수 있다.  


```
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  tags = {
    Name = "terraform-example"
  } 
}
```
```
$ terraform apply
  aws_instance.example: Refreshing state...
  (...)
  Terraform will perform the following actions:
    # aws_instance.example will be updated in-place
    ~ resource "aws_instance" "example" {
    (...) 
     + tags
            + "Name" = "terraform-example"
    
  }
  Plan: 0 to add, 1 to change, 0 to destroy.
  Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.
    Enter a value:
```

이러한 변경사항들을 git과 같은 version control 도구로 관리할 수 있다.  
> 이때, `.terraform`, `*.tfstate`, `*.tfstate.backup` 과 같은 상태 파일은 `.gitignore`에 추가해야한다.  


# Deploying a single web server 
# Deploying a configurable web server 
# Deploying a cluster of web servers 
# Deploying a load balancer
# Cleaning up



# Words
- perspective: 관점, 원근법
- admittedly: 확실히, 명백히

