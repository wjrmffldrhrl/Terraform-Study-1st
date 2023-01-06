# ch3 terraformstate

태그: IaC, Terraform, 스터디, 책

ch2에서 테라폼 apply 테라폼 plan 실행할때마다 테라폼이 리소스가 전에 만들어졌는지 찾을 수 있었고 만들어진 리소스를 각각 업데이트 할 수 있읐음

근데 테라폼을 이를 어떻게 관리하는거?

cli나 테라폼으로 따로 배포하는 경우도 있을거고 다른 aws 계정으로 배포할 수도 있는데? 테라폼은 어떻게 알고 책임 지는거니?

테라폼이 내 인프라를 어떻게 트래킹하고 상태를 확인하고 또 isolating하는지 확인해보자

```
궁금한 단어들
locking file

```

—

# ch3 테라폼 스테이트가 뭘까?

> terraform apply 실행시키면 테라폼은 리소스가 이미 만들어졌는지 어떻게 확인하고선 업데이트를 할까? aws계정 중에 내가 뭘쓰는지는 또 어떻게 아는건데?
> 

`terraform apply`, `terraform plan` 실행 할 때 마다 명령어 실행안 디렉토리 안에  **terraform.tfstate** 생성되거나 업데이트가 되었다.`terraform apply`, `terraform plan` 이런 명령어 실행 할 때마다 테라폼은 해당 리소스가 이미 만들어졌는지 확인하고 업데이트를 해주는데 도대체 테라폼은 이걸 어떻게 아는 것??
그리고 내가 여러개의 AWS 계정 갖고있고 배포하는 것도 테라폼이나 아니면 CLI통해서도 배포 할 수 있는건데 테라폼은 도대체 어떤 인프라를 어떻게 업데이트하고 만들어 낼지 아는걸까???

<aside>
💡  terraform.tfstate 하드코딩해서바꾸지말것

</aside>

**목차**

1. Terraform State이란
2. shared storage for state files
3. limitationg with terraform's backend
4. Terraform Statefile을 분리시키기
- 4-1. workplace을 통해 Terraform Statefile분리하기
- 4-2. 파일 레이아웃을 통해 Terraform Statefile분리하기(원자가 workplace보다 추천)
1. Terraform remote state
- 

## 1. Terraform State이란

- 우리가 테라폼 명령어 실행할때마다 테라폼은은 어떤 리소스가 이미 만들어졌는지 **Terraform state file**에 기록한다.
- 테라폼 명령어 실행한 해당 디렉토리안에 **terraform.tfstate** 디폴트로 JSON포맷으로 만들어진다.
- **terraform.tfstate** 은 JSON형태로 테라폼 설정파일과 매핑 되어있고 AWS계정아이디와 리소스 이름이 적혀 있기 명시되어 있기 때문에 테라폼은 인프라 최신 상태를 provider에서 가져와 무얼 변경해야할지 알 수 있음.
- 근데 개인프로젝트라면 하나의 **terraform.tfstate** 을 사용하는건 문제가 안되겠지만 테라폼을 실제 서비스에서 팀단위로 사용한다면 문제가 생길 수 있다.
1. shared storage for state files : 각 각의 팀멤버가 서비스를 위해 **terraform.tfstate** 를 업데이트하려면 shared storage에 상태파일이 저장되어있어야함.
2. locking state files : 근데 각 각의 팀멤버가 locking파일없이 **terraform.tfstate**에 접근하게 되면 data loss, 상태파일 충돌,테라폼이 상태파일을 concurrent update하는등의 문제가 생길 수 있음
3. isolating state files : 인프라 변경 사항 생길 때 각각의 환경을 분리하는게 좋음. testing, staging, service등

## 2. shared storage for state files

그냥 git에다가 테라폼 파일 하나의 변경 사항 저장하면 좋겠다만 그건 그리 좋은 생각은 아니라고함

- manual error
- locking : 대부분의 버전컨트롤에서는 잠금기능 존재하징낳음 그말은 한명이 수정중일 때 다른한명이 terraform apply 를 날릴 수 있음 이러한거 막아줘야함
- 보안문제secrets : **terraform.tfstate에 정의된 파일에 디비리소스있을 수 있음**

하지만  버전컨트롤이 아니라 remote backend로는 위의 문제를 아래와 같이 해결 가능함

- manual error :
- locking
- secrets

그리고 원작러가 추천하는 방법은 aws s3 + 다이나모디비

aws s3 에서 잠금기능없어서 dynamoDB를 같이씀.

```bash
$ mkdir terraform-ch3
$ cd terraform-ch3
$ touch main.tf 
```

```bash
#  main.tf

# 근데 테라폼state 상태 현재까지로컬이라서 다이나모디비에 저장될수있도록 정의해줘야함
terraform {
  backend "s3"{
    bucket = "terraform-up-and-running-state-crispy-legs"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-lokcs"
    encrypt = true
  }

}

provider "aws" {
  region = "us-east-2"
}

# 다이나모디비는 aws에서 제공한느 키밸류 분산 저장소

# srongly conists read and conditional writes + 분산 잠금기능
resource "aws_dynamodb_table" "terraform_locks"{
  name = "terraform-up-and-running-lokcs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

}

#prevent-destroy -> (lifecycle과 관련된 파라미터중 두번째, create_before_destroy)
resource "aws_s3_bucket" "terraform_state"{
  bucket = "terraform-up-and-running-state-crispy-legs"
  # prvent accidental deletion of this s3 bucket
  lifecycle {
    prevent_destroy = true
  }
  # versioning {} --> deprecated
  # enable versioning so we can see the full revsion history
  versioning {
    enabled = true
  }
  # enable server side encrytion by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

```bash
$ terraform init
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

테라폼 상태파일을 잠금하려고하면 다이나모 디비 꼭 만들어야함 다이나모디비는 prim

테라폼 백엔드 설정할 떄 terraform init → 근데 이거 idempotent라서 여러번 돌려도 됨. 테라폼이 자동으로 로컬 상태파일을 확인해서 s3백엔드에 올릴것. 이 다음부터 테라폼사태파일을 s3에 올릴것. 따라서 지금부터 테라폼은 자동으로 최근상태를 s3으로 부터 올릯어미

## 3. limitationg with terraform's backend

근데 테라폼 백엔드에 인지해야하는 상황이 있음.
테라폼으로 s3을 만들어 테라폼 상태파일을 저장하려고하는건 닭이 먼저냐 달걀이 먼저냐와 같은 문제. 그래서 아래와 같은 두단계를 진행해야함.

1. s3버킷, dynamo db 테이블 생성하는 테라폼 코드를 로컬 백엔드 작성
2. 그 테라포 코드로 돌아가서 추가로 remote backend 설정내용을 추가함. 새로 s3, dynamo db생성하는걸

<aside>
💡 어쩌구 저쩌구 이해안감

</aside>

## 3. Terraform Statefile을 분리시키기

- 3-1. workplace을 통해 Terraform Statefile분리하기

`terraform init --reconfigure` → `terrafrom apply` 

```bash
terraform {
  backend "s3"{
    bucket = "terraform-up-and-running-state-crispy-legs"
    key = "workspace-exmaple/terraform.tfstate" <<변경
    region = "us-east-2"
    dynamodb_table = "terraform-up-and-running-lokcs"
    encrypt = true
  }

}

resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

}
```

`terraform workplace show`  에서 나오는  default가 위에서 생성된거임

그리고 `terraform workspce new exmaple1` 하고 `terraform plan -> terraform apply` 해보면ec2인스턴스가 이미있음에도 불구하고 새로 ec2가 생긴다

그리고 `terraform workspce new exmaple2` 하고 `terraform plan -> terraform apply` 해보면ec2인스턴스가 이미있음에도 불구하고 새로 ec2가 생긴다

default, example1, example2 워크스페이스가 생기고 각 각  terraform apply 코맨드를 통해서 3개의 ec2인스턴스가 생긴거 확인가능

그리고 s3에 테라폼스테이트 담긴 버킷가보면 

![Untitled](ch3%20terraformstate%2030675f02c0384bd59af25725672d3e06/Untitled%201.png)

```bash
$ terraform workspace list
  default
  example1
* example2
```

s3에있는 env폴더에가보면 example1, example2 있는게 보임

따라서 테라폼 명령어에서 워크스페이스를 바꾸는건 s3에서 상태파일경로르 바꾼다고 생각하면 편함

```bash
$ aws s3 ls terraform-up-and-running-state-crispy-legs --recursive --human-readable
4.3 env:/example1/workspace-exmaple/terraform.tfstate
4.2 env:/example2/workspace-exmaple/terraform.tfstate
4.7 global/s3/terraform.tfstate
4.3 workspace-exmaple/terraform.tfstate

```

이러한 기능은 테라폼 모듈 배포했고 다른 상태파일에 영향주고 싶지 안핟면 사용가능 혹은 

워크스페이스상태에따라 모듈을 어떻게 변경할지 아래처럼 사용가능함

만약에 디폴트라면  미디엄으로배포..등

```bash
resource "aws_instance" "example" {
 ami = "ami-0c55b159cbfafe1f0"
 instance-type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"

}
```

근데 아래와같은 단점도 존재함

- same backend → 모든 워크스페이스가 같은 백엔드에 있음 (같은  s3버킷안에) → 프로덕션과 스테이징이 오나전히 분리 되지 않음
- workspace가  현재 테라폼 코드에서 보이지 않음(현재워크스페이스확인안됨)
- 현재 스테이징상태 보기가힘듬

- 3-2. 파일 레이아웃을 통해 Terraform Statefile분리하기(원자가 workplace보다 추천)
- 각 각의 환경변수들을 각 각의 폴더에 넣음 예를들면 stage와 관련된 환경변수는 ㄹ해당 폴더에다가
- diff backend를 각각의 스테이징을 다게 (각 각의 환경은 각 각의 서로다른 s3에 버킷에둠)

만약에 좀 더 나눈다고 하면 환경변수를 컴포넌트 레벨까지 쪼개기(vpc, ec2이런식으로) 따라서 저자는 테라폼 환경변수를 스테이징 + 그리고 컴포넌트 레벨로 쪼개는거 추천

```bash
- stage --------->>>>>>>> env for preproduction 테스팅등
| - vpc
| - services
| | - frontend-app/
| | - backend-app/
| | | - var.tf
| | | - output.tf
| | | - main.tf
| - data-storage/
| | | - mysql/
| | | - redist/

- prod --------->>>>>>>> env for 프로덕션환경
| - vpc
| - services
| | - frontend-app/
| | - backend-app/
| - data-storage/

- mgmt --------->>>>>>>> env for devops툴
| - vpc
| | - services/
| | | - bastion-host/
| | | - jenkins/

- global --------->>>>>>>> env for glbaol 전체쓰이는거
| | - iam/
| | - s3/

```

이렇게 파일 레이아웃으로 만들어진 테라폼파일에서 테라폼은 단순히 tf확장자찾기떄문에 파일명은 상관없다만 공도으로 사용할거니 컨벤션 사용할것..

한편 여기서 frontend, backend 공통사항 많아질거니 이런거는 모듈로 빼자

ch2에서 웹클러스터에제는 아래처럼 나눌수있음 그리고 방금전에 s3에 관한내용은

```bash
$ mkdir -p terraform-test3-file-layout/services/webser-cluster
$ mkdir -p terraform-test3-file-layout/global/s3
$ cd terraform-test3-file-layout/services/webser-cluster
$ touch var.tf output**s**.tf main.tf
$ cd ../../
$ cd terraform-test3-file-layout/global/s3
******************************************************$ touch outputs.tf main.tf******************************************************
```

```bash
-stage/
|-services/
||-webserver-cluster
|||-var.tf
|||-outputs.tf
|||-main.tf

-globals/
|-s3
||-outputs.tf
||-main.tf

```

장점 → 각 스테이지+컴포넌트별로 나눠져서 뭔가 하나가 잘못되어도 전체가 무너질일은없음

단점 → 한번에 날아갈일은 없겠다만 각 디렉토리 돌면서 apply날려줘야함 (하지만 terraform apply-all도있음) 

→ 그리고 dependency 문제 있음. 만약에 app code가 같은  db를 레퍼런스로 쓰고있다면(db……) aksdirdp ??이거 무너말인지

---

1. Terraform remote state

하지만 테라폼에서 ch2보면 aws_subnet_ids같은걸 리스트로 돌려줬음 

이런것처럼 테라폼에서 제공해주는 terraform_remote_state가 있음. 테라폼 상태파일을 리드온리로 읽을수잇음!아까그것처럼

예제) 유저 → 엘라스틱로드밸런서 → ASG → RDS(mysql)

이떄 디비를 ASG랑 같은 컨피그 파일에 두고 싶지 않을거임 왜냐면 클러스터 변경사항 생길 때마다 db가 망가지는 상황은 피하고 싶을 테니 따라서

stage/data-source/mysql/폴더안에다가 만들겠지

```bash
provider "aws" { region = "us-east-2" }
resource "aws_db_instance" "example" {
identifier_prefix="terraform-up-and-running"
engine="mysql"
allocated_storage=10
instance_class="db.t2.micro"
name="exmaple_database"
username="admin"
#how we set this PWD?
password = "???"
}

```

그러면 현재까지 웹클러스터 디렉토리는 요러한 구조가됨

```bash
-stage/
|-services/
||-webserver-cluster
|||-var.tf
|||-output.tf
|||-main.tf
|-data-stores/
||-mysql/
|||-var.tf
|||-outputs.tf
|||-main.tf

-global/
|-s3
||-outputs.tf
||-main.tf

```

근데 `aws_db_instance`  이거사용할때 패스워드를 꼭 해저야함. 플레인텍스트안됨 따라서 1.시크릿매니저 2.키체인(`export TF_VAR_db_passwrod=’””`  

`terrafrom apply` 

```bash
provider "aws" { region = "us-east-2" }
resource "aws_db_instance" "example" {
identifier_prefix="terraform-up-and-running"
engine="mysql"
allocated_storage=10
instance_class="db.t2.micro"
name="exmaple_database"
username="admin"
#how we set this PWD?
password = data.aws_secretmanager_secret_version.db_password.secret_string
}

data "aws_secretmanger_secret_version" "db_password" {
 secret_id = "mysql-master-password-stage"
}
```

그리고선 mysql terraform.tfstate에 s3버킷에 테라폼 상태 바뀔수있도록 아래와같이 작성.. `terraform init` -> terraform apply

```bash
terraform {
backend "s3" {
 bucket = "terraform-up-and-running-crispy-legs"
key = "stage/data-stores/mysql/terraform.tfstate"
region = "us-east-2"
dynamodb_table = "terraform-up-and-running-locks"
encrypt=true
}
}
```

그럼 이제 디비랑 클러스터 연결할건데 웹서버에 이 디비포트를 어떻게 전달할것인가? stage/data-stores/mysql/outputs.tf에 아래와같은 내용

```bash
output "address" {
 value = aws_db_instance.example.address
 description="어쩌고"
}

output "port" {
 value = aws_db_instance.example.port
 description="어쩌고1234"
}
```

그리고 terraform apply한번 더 실행하고 이러한 output도 역시 stage/data-stores/mysql/terraform.tfstate ㅇ에 저장될거임

웹서버 클러스터가 데이터 상태파일을 읽을 수 있게하려면 아래와같이..

stage/services/webserver-cluster/main.tf

```bash
data "terraform_remote_state" "db" {
backend = "s3"
config = {
bucket="(your_name)"
key="stage/data-stores/mysql/terraform.tfstate"
region="us-east-2"
}
}
```

테라폼 데이터 소스는 리드온리 웹클러스터 서버코드가 바꾸는거 아예 없음 소스코드만 읽는거라서

데이터베이스 아웃풋 변수는 상태파일에 저장되고 그러한 것들은terraform_remote_state 데이터 소스를 사용해서 읽을 수 있음

`data.terraform_remote_state.<NAME>.outputs.<ATTRIBUTE>` 

웹클러스터 인스턴스에서 데이터베이서 주소랑 포트번호 가져올려면 아래와 같이 가능

```bash
user_Data = <<EOF
#!/bin/bash
echo "HELLO WORLD" > index.html
echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
```

근데 유저데이터가 길어질고 인라인이 별로게 될건데 테라폼내에서 배쉬쉘 넣을때 이런식으로도 가능 테라폼 기능중하나임

```bash
테라폼함수명(인자) < 이런식으로 호출 예를들면
format(<FMT>, <ARGS>,) < 이게 함수명임
$ terraform console 테라폼콘솔들어가서
> format("%.3f", 0.1235) 
file(<PATH>) < 이런함수도 있음 해당경로에있는 파일 스트링으로 가져옴
그래서 저 긴 배쉬파일읽을려고하면
file("user-data.sh")로 읽고싶겠다만
```

`웹서버클러스터에서 다이나믹한 디비 포트랑 디비주소를 읽고 싶은거기때문에ㄷ
file 함수와 template_file 데이터 소스란걸 써야함` 

---

- 보통 ec2 user-data에다가는 어떤 정보는 넣는지? tf저장하는곳에 쉘파일 넣기도하는지 궁금함

 데어 template_file은 두개 인자로 받는데 template (렌더할 스트링), template(렌더링맵) 결과물로 rendered가 나옴 템플릿

stage/services/webserver-cluster/main.tf

```bash
data "template_file" "user_data" {
template = file("user-data.sh")
vars = {
server_port = var.server_port
db_address = data.terraform_remote_state.db.outputs.address
db_port = data.terraform_remote_state.db.outputs.port
}
}
```

stage/services/webserver-cluster/user-data.sh에 

```bash
#!/bin/bash

cat > index.html <<EOF
<h1> Hello, world </h1>
<p> DB address: ${db_address} </p>
<p> DB port : ${db_port}</p>
EOF

nohub busybox httpd -f -p ${derver_port} &

```

처음 배쉬쉘파일과 달리 변경사항이 있는데 다음과 같음

- 테라폼 문법들어잇음 근데 프리픽스같은거없어도되;ㅁ
- 스크립트안에 html잇음

---

그리고 terraform apply로 아래와 같이 날려주면 끝

```bash
resoure "aws_launch_configuration" "example" {
img_id = "ami-0c55b159cbfaef1fo"
instance_type="t2.micro"
security_groups=[aws_security_group.instance.id]
user_data=data.template_file.user_data.rendered
lifecycle {
 created_before_destroy = true
}
}
```