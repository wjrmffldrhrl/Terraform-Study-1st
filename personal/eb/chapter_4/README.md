# How To Create Reusable Infrastructure With Terraform Modules
# 1: 모듈의 기본

테라폼의 모든 구성은 모듈이다. 하나의 모듈에서 다른 모듈을 사용하는 법을 배워보자

- modules 라는 디렉토리 하위에 각 환경에서 참조할 공통 구성 요소를 작성한다.

모듈을 사용하기 위한 구문은 다음과 같다

```
module "<NAME>" {
  source = "<SOURCE>"

  [CONFIG ...]
}
```

name 은 모듈을 참조하기 위한 식별자이고 source 는 모듈 코드를 찾을 수 있는 경로 이며 config 는 모듈과 관련된 하나 이상의 인수로 구성된다.

```
provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}
```

각 환경의 main.tf 에서 위와 같이 모듈 경로를 지정해 환경에서 재사용할 수 있다. 

<aside>
💡 모듈을 추가하거나 source 매개변수를 수정할 때마다 apply 전에 init 명령어를 실행해야 한다.

</aside>

같은 계정에서 stage 와 production 환경을 나누어 실행 했을때 위와 같이 공통 모듈을 사용하여 환경 구성시 리소스 이름이 중복되어 충돌 오류가 발생한다. 이 문제를 해결하기 위해 모듈에 입력 매개변수를 만들어 리소스 이름을 다르게 만들어주어야 한다.

# 2: 모듈 입력

- 모듈에서 변수 선언
- 모듈의 구성 값 변수로 변경
- 각 환경 구성 파일에서 입력 변수 설정

변수를 사용하기 위해 *modules/services/webserver-cluster/variables.tf* 를 열고 새로운 입력 변수 3개를 추가한다. 

```
variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}
```

모듈의 *module/services/webserver-cluster/main.tf* 를 열고 변수화된 리소스명을 사용한다

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

위의 입력변수를 사용하도록 스테이징 환경의 데이터 소스를 업데이트 한다.

```
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}
```

스테이징 환경의 main.tf 에 세 입력 변수를 설정한다

```
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
}
```

# 3: 모듈과 지역 변수

모듈의 입력을 정의하는 것 외에 모듈 안에서 계산을 수행하거나 코드가 중복되지 않게끔 모듈에서 변수를 정의하는 방법이 필요하다. 

예를 들어 아래의 로드밸런서는 HTTP 기본 포트인 80 포트로 리스닝한다. 여러 곳에 해당 포트가 하드 코딩되어 있는데 이를 지역 변수로 대체할 수 있다.

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

locals 블록에서 로컬 값으로 정의한다

```
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
```

로컬 값은 다음과 같은 구문으로 로컬참조를 사용한다

```
local.<NAME>
```

```
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
```

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}
```

# 4: 모듈 출력

모듈의 출력 값을 반환 받아 다른 리소스에서 참조할 수 있다. 

예를 들어 오토스케일링그룹에서 주어진 주기마다 스케쥴을 실행하고 싶을때 모듈에서 생성한 오토스케일링 그룹 이름을 참조하여 오토스케일링 스케쥴 룰에 구성해주어야 한다. 

```
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"
  autoscaling_group_name = <오토스케일링 그룹 명>
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"
  autoscaling_group_name = <오토스케일링 그룹 명>
}
```

*/modules/services/webserver-cluster/outputs.tf* 에 출력 변수를 추가한다

```
output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
```

다음 구문을 사용하여 모듈 출력 변수에 액세스할 수 있다.

```
module.<MODULE_NAME>.<OUTPUT_NAME>
```

예를 들어:

```
module.frontend.asg_name
```

프로덕션 환경의 main.tf 에 오토스케일링 그룹 스케쥴을 구성한다

```
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
```

# 5: 모듈 주의 사항

- 파일 경로
- 인라인 블록

## 5.1 파일 경로

내장 함수 file 을 사용해 외부 파일을 읽을 때 파일 경로는 상대 경로여야 한다. 테라폼은 현재 작업 중인 디렉터리를 기준으로 경로를 해석한다. 즉 apply 를 실행하는 루트 모듈에서 file 함수를 사용하는 것은 가능하지만 별도 폴더에서 정의된 모듈에서 file 함수를 사용할 수 없다. 이 문제를 해결하기 위해 path.<TYPE> 형태의 경로 참조 표현식을 사용할 수 있다. 

- `path.module` 표현식이 정의된 모듈의 파일 시스템 경로를 반환
- `path.root` 루트 모듈의 파일 시스템 경로를 반환
- `path.cwd` 현재 작업 디렉토리의 파일 시스템 경로를 반환

사용자 데이터 스크립트의 경우 모듈 자체에 대한 상대 경로가 필요하므로 함수 `path.module` 를 호출할 때 사용해야 한다.

예: module*/services/webserver-cluster/main.tf 에서

```
user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })
```

## 5.2 인라인 블록

일부 테라폼 구성은 인라인 블록 혹은 별도의 리소스로 정의할 수 있다. 

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}
```

인라인 블록을 사용하면 사용자는 모듈 외부에서 별도의 송수신 규칙을 추가할 방법이 없다.

위를 별도의 리소스 aws_security_group_rule 를 사용해 수신 및 송신 규칙을 정의하도록 모듈을 변경 해보자.

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}
```

위의 리소스에서 시큐리티 그룹 id를 알아야 하므로 *module/services/webserver-cluster/outputs.tf*에 출력변수를 설정한다 

```
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
```

스테이징 환경에서 추가 포트를 노출해야 하는 경우 *stage/services/webserver-cluster/main.tf 에* `aws_security_group_rule` 리소스를 추가할 수 있다.

```
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  # (parameters hidden for clarity)
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id

  from_port   = 12345
  to_port     = 12345
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

# 6: 모듈 버전 관리

 운영과 스테이징에서 공통 모듈을 사용하면 최초의 같은 소스를 운영과 스테이징 환경에서 사용할 경우 나타나는 문제를 다시 겪게 된다. 이를 해결하기 위해 공통 모듈에 버져닝을 적용한다.


모듈의 코드를 별도의 깃 레포에 넣고 소스 매개변수를 해당 레포의 URI 로 설정한다. 

- 모듈
    - 재사용 가능한 모듈을 정의한다.
- 라이브
    - 스테이징, 프로덕션, 관리 등 각 환경에서 실행 중인 인프라를 정의한다



모듈에 버전을 사용하기 위해 태그를 추가한다.

```
$ cd modules
$ git init
$ git add .
$ git commit -m "Initial commit of modules repo"
$ git remote add origin "(URL OF REMOTE GIT REPOSITORY)"
$ git push origin main

$ git tag -a "v0.0.1" -m "First release of webserver-cluster module"
$ git push --follow-tags
```

소스 매개 변수에 깃 URL 을 지정해 스테이징 환경과 프로덕션 환경에서 지정된 버전의 모듈을 사용한다.

```
module "webserver_cluster" {
  source = "github.com/foo/modules//services/webserver-cluster?ref=v0.0.1"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
```

ref 매개변수를 사용하면 sha1 해시를 통해 특정 깃 커밋을 지정하거나 브랜치 이름, 태그를 지정할 수 있다. 브랜치 이름으로 지정할 경우 해당 브랜치의 최신 커밋을 가져오기 때문에 브랜치 이름은 버전 번호로 사용하기에 부적합 하다.