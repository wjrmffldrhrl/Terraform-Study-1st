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



# Limitations with Terraform’s backends 
# State file isolation
## Isolation via workspaces
## Isolation via file layout
# The terraform_remote_state data source


