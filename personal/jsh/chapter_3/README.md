# How to Manage Terraform State
테라폼이 상태를 관리하는 방법

# What is Terraform state?
Terraform은 실행하면 `terraform.tfstate` 파일을 생성한다.  
- JSON format으로 구성된 Terraform resource mapping record다.  

이후, Terraform을 실행하면 AWS의 상태를 가져와서 해당 파일과 비교하고 차이점을 출력한다.  
- `terraform plan`이 이 동작을 수행한다.  

Terraform을 혼자서만 쓴다면 local에서 state가 관리되지만 team 단위로 활용한다면 몇 가지 문제점이 있다.  
- Shared storage for state files
    - 모든 팀원들이 같은 state file에 접근해야한다.
    - 이것은 state file이 공용 공간에 보관되야 한다는걸 의미한다.
- Locking state files
    - 두 명 이상의 팀원이 같은 state file을 수정하고 Terraform을 실행하면 conflict가 발생하며 데이터 유실 및 state file 손상이 있을 수 있다.
- Isolating state files
    - Test나 staging 환경을 구성할 때 production 환경을 깨지 않도록 확실히 해야한다.  
    - State file을 어떻게 isolating할 것인가?


# Shared storage for state files 
Terraform code는 version control에서 관리해야하지만, Terraform state는 version control에서 관리하면 안된다.  

- Manual error
    - Terrafom을 실행하기 전이나 Terraform이 상태를 변경 후에 state를 업데이트하는걸 잊을 수 있다.
    - 팀의 누군가가 최신화되지 않은 상태 파일로 Terraform을 실행하여 인프라를 초기화하거나 중복되게 하는건 시간문제다.
- Locking
    - 대부분의 version control system은 locking을 제공하지 않는다.
- Secrets
    - 모든 Terraform state는 plain text로 저장되며 이는 보안 문제로 이어진다.
    - 예를 들어 `aws_db_instance`를 생성하면 state file에 username과 password를 저장하고 이는 노출될 수 있다.

위와 같은 문제점을 해결하기 위해 state를 shared storage에서 관리하는 것이 좋다.  

Terraform은 state를 저장하고 가져올 방법을 정하는 backend가 있다.  
기본값은 local disk이며 remote backend를 사용하면 공유 공간에 state를 저장할 수 있도록 한다.  
- S3, Azure Storage, GCS, HashiCorp's Terraform Cloud, Terraform Enterprise

Remote backend는 위 세 가지 문제를 해결한다. 
- Mannual error
    - Terraform이 자동으로 state를 가져오고 업데이트한다.
- Locking
    - 대부분의 remote backend는 locking을 지원한다.
    - `terraform apply -lock-timeout=<TIME>`
- Secrets
    - 대부분의 remote backend는 state file의 보안을 지원한다.
        - ex) AWS의 IAM
    - State file이 로컬에 저장되지 않는다.  


S3를 remote backend로 사용기 위해서는 bucket 생성 후 `main.tf`에서 provider와 state를 구성해주면 된다. 

```terraform
provider "aws {
    region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-state"

    # Prevent accidental deletion of this S3 bucket
    lifecycle {
        prevent_destroy = true
    } 
}
```
- prevent_destroy: resource에 해당 옵션을 true로 두면 해당 리소스를 제거하는 모든 Terraform 동작은 error를 발생시킨다.  

추가로 bucket을 보호하기 위한 몇가지 동작을 수행한다.

### 1. Versioning
```terraform
# Enable versioning so you can see the full revision history of your
# state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```
### 2. Server-Side Encryption
```terraform
# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    } 
}

```
### 3. Public Access Block
```terraform
# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket                  = aws_s3_bucket.terraform_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}
```

Bucket 보호가 끝났으면 locking을 위한 DynamoDB table을 생성한다.  
- 이때, 테이블의 PK는 `LockID`로 지정해야 한다.
```terraform
resource "aws_dynamodb_table" "terraform_locks" {
    name         = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"
    attribute {
        name = "LockID"
        type = "S"  
    } 
}
```  

S3와 DynamoDB를 구성한 뒤에는 backend에서 해당 저장소들을 사용하도록 구성해야 한다.  

```terraform
terraform {
  backend "<BACKEND_NAME>" {
    [CONFIG...]
  }
}
```
BACKEND_NAME은 원하는 이름을 지정하면 되고 CONFIG는 한 개 이상의 argument가 존재한다.  

```terraform
terraform {
    backend "s3" {
    # Replace this with your bucket name!
        bucket          = "terraform-up-and-running-state"
        key             = "global/s3/terraform.tfstate"
        region          = "us-east-2"

        # Replace this with your DynamoDB table name!
        dynamodb_table  = "terraform-up-and-running-locks"
        encrypt         = true
    }
}
```
이후 `terraform init`을 수행하면 상태값이 S3에 저장된다.  



# Limitations with Terraform’s backends 
### Chicken and Egg Situation
State를 저장할 S3 Bucket을 Terraform으로 만들기 위해서는 아래 두 단계를 거쳐야 한다.  

1. S3 bucket과 DynamoDB를 만들기 위한 코드 작성 후 local backend에서 배포
2. Terraform 코드에서 생성된 bucket과 DynamoDB를 바라보도록 remote backend configuration 수정후 `terraform init`으로 local state copy

제거하는 경우에도 마찬가지다.  
1. Terraform 코드에서 backend configuration 제거후 `terraform init`으로 state를 로컬로 copy
2. `terrafom destroy`로 S3 bucket과 DynamoDB 제거  

이미 구성되어있는 S3 bucket에 state를 관리한다면 위와 같은 과정은 필요 없을것이고 위와 같은 동작도 모든 Terraform 코드에서 한 번만 수행하면 되기 때문에 큰 문제는 아니라고 생각한다.  

### Backend block variables or reference
`backend` block은 어느 변수값이나 참조를 사용할 수 없다.  
```terraform
# This will NOT work. Variables aren't allowed in a backend configuration.
terraform {
    backend "s3" {
        bucket         = var.bucket
        region         = var.region
        dynamodb_table = var.dynamodb_table
        key            = "example/terraform.tfstate"
        encrypt        = true
    } 
}
```
즉, bucket이나 region 정보 등 모든 값을 수동으로 넣어야 한다는 것이다.  
- 모든 Terrafom module에서 해야된다.
- Module이 많아질수록 어지러워진다.  

Copy and paste가 아닌 command 옵션에서 `-backend-config`로 값을 전달할 수 있긴 하다.  

반복되는 설정값들을 `backend.hcl` 파일로 생성한다.
```hcl
# backend.hcl
bucket         = "terraform-up-and-running-state"
region         = "us-east-2"
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true
```  

이후 `-backend-config` 옵션으로 설정 파일을 전달하면 된다.  
```
$ terraform init -backend-config=backend.hcl
```

> 이런식으로도 가능하다
```
$ terraform init \
    -backend-config="address=demo.consul.io" \
    -backend-config="path=example_app/terraform_state" \
    -backend-config="scheme=https"
```

[Terragrunt](https://terragrunt.gruntwork.io/)라는 오픈소스를 사용하는 방법도 있다.  
- backend 코드의 반복을 줄여주는 도구  





# State file isolation
## Isolation via workspaces
## Isolation via file layout
# The terraform_remote_state data source


