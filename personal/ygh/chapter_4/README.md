# Chapter4: 테라폼 모듈로 재사용 가능한 인프라 구현하기

```
❗️ 책에서의 코드 예제는 production 서버와 stage 서버를 동일한 VPC에 배포한다는 점에 주의
```

- 모듈: 재사용 가능하고 유지 관리 가능하며 테스트 가능한 Terraform 코드를 작성하기 위해 테라폼으로 리소스를 생성하는 한 **프로젝트**를 묶어서 오브젝트로 사용하는 것

실제 개발에서는 내부 테스트를 위한 stage 서버와 production 서버로 나누어서 배포가 된다.

Stage 서버의 환경은 production 서버의 환경과 거의 동일하므로, stage서버에 배포된 코드를 복사해서 붙여넣는 과정을 최소화하는 방안을 마련하는 것이 편리하다.

테라폼에서는 기능을 수행하는 코드를 테라폼 모듈 안에 넣으면 해당 모듈을 다른 프로젝트에서 불러와서 사용할 수 있다 (개발언어의 함수와 유사).

</br>

## 모듈 기본

- 하나의 폴더에 들어있는 테라폼 configuration 파일들을 하나의 모듈로 볼 수 있다.

- 프로젝트 폴더 최상단에서 apply 명령어를 바로 실행하면, 루트 모듈을 실행한다.

예를 들어, 다음과 같은 프로젝트 폴더가 있다고 가정하자.

```
.        
├── stage
│   └── services
│   │     └── webserver-cluster
│   │         ├── main.tf
│   │         └── (etc)
│   └── data-stores
│       └── mysql
│           ├── main.tf
│           └── (etc)
├── prod
│   └── services
│   │     └── webserver-cluster
│   │         ├── main.tf
│   │         └── (etc)
│   └── data-stores
│       └── mysql
│           ├── main.tf
│           └── (etc)
└── global
    └── s3
        ├── main.tf
        └── (etc) 
```

가장 기본적인 과정으로는 `stage/service/webserver-cluster`에서 인프라를 구성해서 배포 한 후, production 폴더에 모든 코드를 붙여넣은 후 다시 실행 시킬 수 있다.

하지만 이런 과정은 번거로우므로 테라폼의 `module`을 이용해 한 곳에서 코드를 관리하고 stage와 proudction 프로젝트 폴더에서 각각 코드를 가져와서 배포하도록 만들 수 있다.

1. stage에서 구성했던 인프라 코드들을 `modules/services/webserver-cluster`로 옮겨준다 (폴더명은 예시이다).

2. `modules/services/webserver-cluster`의 `main.tf`에서 provider 정의를 삭제한다 (provider는 각 root모듈(`main.tf`)에서만 정의될 수 있기 때문).

3. stage와 production 폴더의 `main.tf`에서 새로 provider를 정의한다.

4. modules에 있는 모듈을 가져와서 사용한다. 다음과 같이 가져와서 사용할 수 있다.

```
module "<모듈 이름(파일들이 묶여있는 폴더 이름)>" {
    source = "<가져올 모듈이 있는 경로>"
    [CONFIG ...] #해당 파일에서 새로 정의되는 모듈 configuration. 변동 사항 없으면 따로 정의하지 않아도 됨
}
```

아마도 `production/services/webserver-cluster/main.tf`의 파일 내용은 다음과 같을 것이다.

```
provider "aws" {
    region = "us-northeast-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
}
```

하지만 이 상태로 코드를 돌리면 구성된 모듈의 이름이 hard coding되어 있으므로 배포시 conflict 에러가 발생한다 (stage 서버와 production 서버에서 동일한 이름으로 리소스를 정의하기 때문).

따라서 webserver-cluster 모듈에 추가적인 설정을 해주어야 한다.

</br>

## 모듈 입력값

`module/services/webserver-cluster/variables.tf`에 새로운 변수를 정의한다.

```
variable "clsuter_name" {
    description = "모든 클러스터 리소스에 붙일 이름"
    type = string
}

variable "db_remote_state_bucket" {
    description = "데이터베이스의 원격 상태값을 저장할 s3 버켓 이름"
    type = string
}

variable "db_remote_state_key" {
    description = "데이터베이스의 원격 상태값을 저장할 s3 경로"
    type = string
}
```

위와 같이 정의해주면 modules의 `main.tf`와 stage, proudction의 `main.tf`에서 각각 다음과 같이 정의해줌으로써 하나의 코드로 리소스를 생성하지만 각기 다른 이름으로 구축되어 충돌을 피할 수 있다.

```
# modules/service/webserver-cluster/main.tf

resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"

    ingress {
        ...
    }

    egress {
        ...
    }
}
```

```
# stage/service/webserver-cluster/main.tf

module "webserver_cluster" {
    source = "../../../modules/service/webserver-cluster"

    cluster_name = "webservers-stage" # 생성되는 보안그룹 이름: webservers-stage-alb
    db_remote_state_bucket = "stage-bucket" # stage 구축 시에는 이 값이 db_remote_state_bucket 변수의 값으로 들어감
    db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate" # stage 구축 시에는 이 값이 db_remote_state_key 변수의 값으로 들어감
}
```

```
# prod/service/webserver-cluster/main.tf

module "webserver_cluster" {
    source = "../../../modules/service/webserver-cluster"

    cluster_name = "webservers-prod" # 생성되는 보안그룹 이름: webservers-prod-alb
    db_remote_state_bucket = "prod-bucket" # prod 구축 시에는 이 값이 db_remote_state_bucket 변수의 값으로 들어감
    db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate" # prod 구축 시에는 이 값이 db_remote_state_key 변수의 값으로 들어감
}
```

만약 stage 서버와 production 서버의 instance 설정을 다르게 하고 싶은 경우, ec2의 instance type이나 auto scaling group의 min/ max size를 변수로 둠으로써 이를 조정할 수도 있다.

결국 변수는 name confliction이 발생하는 곳 뿐 아니라 하나의 모듈을 사용하되 세부 설정이 다르게 들어가야할 경우 활용할 수 있다.

</br>

## `locals`

 `locals`는 프로그래밍 언어에서 지역변수와 같이 생각할 수 있으며, 다음과 같은 경우 사용할 수 있다.
 - 특정 값들을 연산하여 하나의 변수를 정의해야 할 경우
 - 모듈 내에서 여러 번 재사용하는 값이 있을 때 (하나의 모듈이 scope)

예를 들어, CIDR block에서 0.0.0.0/0 은 "모든 IP"를 의미하고, 프로토콜에서 -1은 모든 프로토콜을 의미한다.
이 때, 이를 변수로 정의하게되면 해당 값은 모듈 내나 다른 곳에서 실수로 재정의 될 수 있다.

`locals`는 정의된 하나의 모듈 내에서만 사용되고, 다른 모듈에서는 접근할 수 없다. 즉, `modules/services/webserver-cluster/`내에 정의된 `locals`는 `stage/.`나 `prod/.`에서 사용하거나 재정의 할 수 없다. 따라서 두 서버 모두에서 공통적으로 사용되는 값만 정의해야한다.

`locals`는 다음과 같이 정의하며, `local.<이름>` 형태로 접근할 수 있다.

```
# modules/services/webserver-cluster/local.tf

locals {
    http_port = 80
    any_port = 0
    any_protcol = "-1"
    tcp_protocol = "tcp"
    all_ips = ["0.0.0.0/0"]
}
```

```
# modules/services/webserver-cluster/main.tf

resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"

    ingress{
        from_prot = local.http_port # stage, prod 모두에서 80이 들어간다
        to_port = local.http_port # stage, prod 모두에서 80이 들어간다
        protocol = local.tcp_protocol # stage, prod 모두에서 TCP가 들어간다
        cidr_blocs = local.all_ips # stage, prod 모두에서 ["0.0.0.0/0"]이 들어간다
    }

    egress {
        ...
    }
}
```

또는 다음과 같이 variables를 가져와서 변수를 만들 수도 있다.

```
locals {
    tags = merge (
        var.tag1,
        var.tag2
    )
}
```

### locals 와 variables의 차이

- locals는 사용자 값으로 정의되지 않고, 의미있거나 읽기 쉬운 결과를 생성하기 위해 사용한다.
- locals는 동적인 표현이나 리소스의 인수로 사용하기위한 값들을 정의한다.
- locals는 terraform plan, lifecycle, apply, destory 등 terraform 수행에 따라 변하는 값으로 정의되지 않는다.

</br>

## 모듈의 Output

어떤 리소스에서 다른 리소스의 출력값을 받아서 사용해야할 때 `output`을 사용해 접근할 수 있다.

예를 들어, `prod/services/webserver-cluster/main.tf`에 오토 스케일링 스케줄을 정의할 때, 오토 스케일링을 할 대상인 `modules/services/webserver-cluster/main.tf`를 통해 생성한 load balancer dns 이름이 `autoscaling_group_name`키의 값으로 들어가야한다. 그럴 때 다음과 같이 `output`을 사용하여 작성할 수 있다.

```
# prod/services/webserver-cluster/main.tf

resource "aws_autoscaling_schedule" "scaling_out" {
    schedule_action_name = "scaling_out"
    ...

    autoscaling_group_name = module.webserver_cluster.asg_name
}
```

```
# modules/services/webserver-cluster/outputs.tf

output "alb_dns_name" {
    value = aws_lb.example.dns_name # example에는 리소스에서 정의한 aws_lb의 리소스 이름이 들어간다
    description = "load balancer의 도메인 이름"
}
```

여기서 끝이 아니라 오토 스케일링 스케줄 리소스를 생성하는 주체는 `prod/.` 폴더이기 때문에 이 output 값을 prod폴더에 전달해줘야한다.

```
# prod/services/webserver-cluster/outputs.tf

output "alb_dns_name" {
    value = module.webserver_cluster.alb_dns_name
    description = "load balancer의 도메인 이름"
}
```

</br>

## 모듈 사용시 주의점

### 파일 경로
---

 테라폼은 현재의 작업 디렉토리를 기준으로 경로를 인식한다. 따라서 `terraform apply`를 수행하는 위치를 root로 했을 때 코드 내의 파일 경로들이 작성되고, main.tf가 위치해야 한다.

 사고를 방지하기 위해 테라폼에서 제공하는 경로 관련 표현들을 사용할 수 있다.

 - `path.module`

 표현이 정의되어 있는 모듈의 파일 시스템 경로를 리턴한다.

 - `path.cwd`

 현재 작업 디렉토리의 파일 시스템 경로를 리턴한다. 일반적으로 `path.root`와 동일하나, 모듈을 여기 저기서 가져와 사용할 경우, root module의 경로가 변하므로 달라지는 경우가 발생하기도 한다.

 path 표현은 다음과 같이 사용할 수 있다.

 ```
 user_data = templatefile("${path.module}/user-data.sh".{
    ...
 })
 ```

</br>

### 인라인 블럭
---

 일부 테라폼 리소스는 인라인 블럭을 사용해 하나로 정의할 수도 있고, 별도의 리소스로 정의할 수도 있다.
 
 중요한 것은 둘을 섞어쓰지 않는 것이다 (에러남) - 책에서는 별도의 리소스로 정의하는 것을 권장한다.

 예로 보안 그룹 리소스를 들 수 있다.

 - 인라인 블록으로 정의

 ```
 resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"

    ingress {
        ...
    }

    egress {
        ...
    }
 }
```

 - 별도의 리소스로 정의하기
 
 ```
 resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"
 }

 resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    ...
 }

 resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id

    ...
 }
 ```
 이렇게 별도의 리소스로 정의하면 `aws_security_group_rule`의 `security_group_id`키에 보안그룹을 생성한 후 만들어지는 id가 들어가야하므로 `output` 정의가 추가로 필요하다. 하지만 stage서버에서만 포트 개방을 하는 등 내부 리소스에 변수를 줘야할 때 다음과 같이 정의함으로써 유연하게 사용할 수 있다.

 ```
 # stage/services/webserver-cluster/main.tf

 module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
    ...
 }

 resources "aws_security_group_rule" "allow_test_inbound" {
    # ingress를 stage서버만 따로 추가함. modules에서 별도 리소스로 정의하지 않고 inline으로 정의한 경우에는 ingress만 stage에서 별도로 정의할 수 없음
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id

    ...
 }
 ```

</br>

## 모듈 버저닝하기

 만약 하나의 `module` 폴더에서 `production` 폴더와 `stage` 폴더 모두 모듈을 가져와서 사용한다면, `module` 폴더의 코드 변화에 두 환경 모두 영향을 받을 것이다.

 보통 개발을 할 때, proudction 서버에는 영향을 주지 않은 채로 stage 서버에 코드 변화를 줘야 하므로, `module` 폴더를 버저닝하는 것이 필요하다.

 > 💡 TIPS: 지금까지의 예시에서는 `module`폴더의 위치가 로컬에 있었는데, 테라폼에서는 모듈 소스로 Git URL, Mercurial URL 또는 HTTP URL도 지원한다.

버저닝을 하는 가장 간단한 방법은 `source` 파라미터를 활용하는 것이다.

먼저, 테라폼 코드를 위한 Git repository를 두 개를 만들어, 각각 모듈 코드와 stage/ production 코드를 배포한다. 전자의 repository를 `moduels`, 후자의 repository를 `live`라고 명명했을 때, 구조는 다음과 같을 것이다.

```
.
├── modules
│   └── services
│       └── webserver-cluster
│           └── ...           
└── live
    ├── stage
    │   ├──services
    │   │  └── webserver-cluster
    │   │      └── ...
    │   └── data-stores
    │       └── mysql
    │           └── ...
    ├── production
    │   ├──services
    │   │  └── webserver-cluster
    │   │      └── ...
    │   └── data-stores
    │       └── mysql
    │           └── ...
    └── global
        └── s3
            └── ...
```

 그 다음 `live` 폴더 코드를 커밋하고, 태그로 버전을 달아준 뒤 (`git tag -a "태그 값 (버전)"`) push를 한다. 그러면 해당 버전을 URL로 참조할 수 있고, 기존의 로컬 경로로 stage와 production에서 `source` 파라미터로 참조했던 모듈 경로를 해당 버전 경로로 변경해주면 된다.

 만약 원격 레포지토리 플랫폼으로 Github을 사용했다면, 다음과 같이 stage 또는 production의 코드를 변경함으로써 다른 버전의 모듈을 참조할 수 있게 한다.

 ```
 module "webserver_cluster" {
    source = "github.com/{owner}/modules//services/webserver-cluster?ref={태그 값}"
    # 기존에 "../../../modules/service/webserver-cluster"로 참조하던 파라미터
    # 이제는 {태그 값}을 변경해줌으로써 production과 stage에서 다른 소스를 참조할 수 있게 한다.
    
    ...
 }
 ```
 위와 같이 코드 수정과 git push가 완료되었다면 `terraform init`과 `terraform apply`를 통해 로컬에서 배포를 수행하거나, 원격 레포지토리를 땄으므로 CICD 환경을 구축할 수 있다.

 CICD 환경을 구축한 경우, `modules`레포지토리가 private repo라면 배포 시 띄워지는 VM에 `modules` 접근 권한을 줘야하므로 SSH 인증 절차가 필요할 수 있다.

 마지막으로 버저닝 룰에 대해 잠깐 알아보자면, 일반적으로 버전은 `v{major}.{minor}.{patch}`로 구성되며 다음 규칙을 따라 변경한다.

 - `major` : 이전 버전과 호환되지 않는 변경이 일어났을 때 올리는 숫자이다. 예) 프레임워크 변경, 함수 변경 또는 삭제, 이름 변경
 - `minor` : 이전 버전과 호환이 가능한 변경이 일어났을 때 올리는 숫자이다. 예) 기능 추가, 컴포넌트 추가, 클래스 추가
 - `patch` : 이전 버전에서 사소한 수정이 일어났을 때 올리는 숫자이다. 예) 버그 수정, 디자인 변경
