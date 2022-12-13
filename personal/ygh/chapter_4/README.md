# Chapter2: 테라폼 모듈로 재사용 가능한 인프라 구현하기

❗️ 책에서의 코드 예제는 production 서버와 stage 서버를 동일한 VPC에 배포한다는 점에 주의

- 모듈: 재사용 가능하고 유지 관리 가능하며 테스트 가능한 Terraform 코드를 작성하기 위한 핵심 요소

실제 개발에서는 내부 테스트를 위한 stage 서버와 production 서버로 나누어서 배포가 된다.

Stage 서버의 환경은 production 서버의 환경과 거의 동일하므로, stage서버에 배포된 코드를 복사해서 붙여넣는 과정을 최소화하는 방안을 마련하는 것이 편리하다.

테라폼에서는 모듈을 통해 이를 구현할 수 있는데, 기능을 수행하는 코드를 테라폼 모듈 안에 넣으면, 해당 모듈을 다른 파일에서 불러와서 사용할 수 있다 (개발언어의 함수와 같음).

## 모듈 기본

- 하나의 폴더에 들어있는 테라폼 configuration 파일들을 하나의 모듈로 볼 수 있다.

- 모듈에 apply명령어를 바로 실행하면, 루트 모듈을 실행한다.

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

`stage/service/webserver-cluster`에서 인프라를 구성했고, 성공했을 때, production 폴더에 모든 코드를 붙여넣은 후 다시 실행 시킬 수 있다.

또는, 프로젝트 폴더를 다음과 같이 구성한 후,

1. stage에서 구성했던 인프라 코드들을 `modules/services/webserver-cluster`로 옮겨준다.

2. modules/services/webserver-cluster의 main.tf에서 provider 정의를 삭제한다. (provider는 root모듈에서만 정의될 수 있기 때문)

3. production 파일에서 새로 provider를 정의한다.

4. modules에 있는 모듈을 가져와서 사용한다. 다음과 같이 가져와서 사용할 수 있다.
```
module "<모듈 이름(파일들이 묶여있는 폴더 이름)>" {
    source = "<가져올 모듈이 있는 위치>"
    [CONFIG ...] #해당 파일에서 새로 정의되는 모듈 configuration
}
```

아마도 production/services/webserver-cluster/main.tf의 파일 내용은 다음과 같을 것이다.

```
provider "aws" {
    region = "us-northeast-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
}
```

하지만 이 상태로 코드를 돌리면 구성된 모듈의 이름이 hard coding되어 있으므로 conflict 에러가 발생한다. 따라서 webserver-cluster 모듈에 추가적인 설정을 해주어야 한다.

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

위와 같이 정의해주면 `modules/service/webserver-cluster/main.tf`, stage와 proudction의 `main.tf`에서 각각 다음과 같이 정의해줌으로써 하나의 코드로 리소스를 생성하지만 각기 다른 이름으로 구축되어 충돌을 피할 수 있다.

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

## `Locals`

 `locals`는 다음과 같은 경우 사용할 수 있다.
 - 계산을 수행하여 변수를 정의해야할 경우
 - 코드를 반복 작성하고 싶지 않지만 input을 노출하고 싶지도 않은 경우

예를 들어, CIDR block에서 0.0.0.0/0 은 "모든 IP"를 의미하고, 프로토콜에서 -1은 모든 프로토콜을 의미한다. 하지만 다른 모듈에서는 아닐 수 있다.
이 때, 이를 변수로 정의하게되면 해당 값은 모듈 내나 다른 곳에서 재정의 될 수 있다.

`locals`는 정의된 하나의 모듈 내에서만 사용되고, 다른 모듈에서는 접근할 수 없다. 즉, `modules/services/webserver-cluster/main.tf`에 정의된 `locals`는 `stage/...`나 `prod/..`에서 사용하거나 재정의 할 수 없다. 따라서 두 서버 모두에서 공통적으로 사용되는 값만 정의해야한다.

`locals`는 다음과 같이 정의하며, `local.<이름>` 형태로 사용할 수 있다.

```
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

여기서 끝이 아니라 오토 스케일링 스케줄 리소스를 생성하는 주체는 `prod/...` 폴더이기 때문에 이 output 값을 prod폴더에 전달해줘야한다.

```
# prod/services/webserver-cluster/outputs.tf

output "alb_dns_name" {
    value = module.webserver_cluster.alb_dns_name
    description = "load balancer의 도메인 이름"
}
```

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

## 모듈 버저닝하기

```
.
├── modules
│   └── services
│       └── webserver-cluster
│           ├── main.tf
│           └── (etc)            
├── stage
│   └── services
│   │     └── webserver-cluster
│   │         └── main.tf
│   └── data-stores
│       └── mysql
│           └── main.tf
├── production
│   └── services
│   │     └── webserver-cluster
│   │         └── main.tf
│   └── data-stores
│       └── mysql
│           └── main.tf
└── global
    └── s3
        ├── main.tf
        └── (etc) 
```

위의 폴더에 있던 파일들을 모두 `modules/services/webserver-cluster`로 이동시킨 뒤