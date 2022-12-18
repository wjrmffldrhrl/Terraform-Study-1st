# 4. 테라폼 모듈로 재사용 가능한 인프라 생성하기

## 1. 모듈의 기본

- 폴더에 있는 모든 테라폼 구성 파일은 모듈
    
    ![스크린샷 2022-12-13 오후 9.53.33.png](4%20%E1%84%90%E1%85%A6%E1%84%85%E1%85%A1%E1%84%91%E1%85%A9%E1%86%B7%20%E1%84%86%E1%85%A9%E1%84%83%E1%85%B2%E1%86%AF%E1%84%85%E1%85%A9%20%E1%84%8C%E1%85%A2%E1%84%89%E1%85%A1%E1%84%8B%E1%85%AD%E1%86%BC%20%E1%84%80%E1%85%A1%E1%84%82%E1%85%B3%E1%86%BC%E1%84%92%E1%85%A1%E1%86%AB%20%E1%84%8B%E1%85%B5%E1%86%AB%E1%84%91%E1%85%B3%E1%84%85%E1%85%A1%20%E1%84%89%E1%85%A2%E1%86%BC%E1%84%89%E1%85%A5%E1%86%BC%E1%84%92%20d6e83260f7314f7a9a4722057255a843/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-13_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_9.53.33.png)
    
- `modules` 이라는 파일 아래에 함수처럼 재사용 가능한 파일 만들고 이를 여러 환경에서 가져다가 사용
    - `stage` 와 `prod` 모두 해당 폴더를 참조
- `module` 의 `main.tf` 에는 `provider` 제거
    - `provider` 는 모듈 자체가 아닌 그걸 가져다가 쓰는 사용자가 정의한 모듈로 정의해야 함
- 각 환경에서 아래와 같은 형식으로 사용

```bash
module "<NAME>" {     # 식별자
	source = "<SOURCE>" # 어떤 모듈을 가져다가 사용할건지

	[CONFIG ...]
}
```

```bash
# stage
provider "aws" {
	region = "us-east-2"
}

module "webserver_cluster" {
	source = "../../../modules/services/webserver-cluster"
}

# prod
provider "aws" {
	region = "us-east-2"
}

module "webserver_cluster" {
	source = "../../../modules/services/webserver-cluster"
}
```

## 2. 모듈 입력

- 환경마다 쓰이는 리소스가 다르기 때문에 환경마다 필요한 리소스 변수를 동적으로 넘겨주어야 한다.
- 함수에 매개 변수를 넘겨주는 것처럼 모듈에도 `module/.../variables.tf` 로 변수를 넘겨준다.

```bash
# module/.../variables.tf
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

- `module/.../main.tf` 에서 이를 사용할 수 있다.

```bash
# module/.../main.tf
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}
```

- 사용자가 모듈의 `main.tf`을 사용하기 위해 이를 가져와서 매개 변수를 넘기면 이를 모듈에서 변수로 활용할 수 있음.
    - 함수와 똑같음

```bash
# stage/.../main.tf
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "bucket_name"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
	
	# 환경마다 다르게 사용
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
```

```bash
# module/.../main.tf의 ASG resource
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}
```

```bash
# module/.../main.tf의 terraform_remote_state data 소스
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}
```

## 3. 모듈과 지역 변수

- 변수를 구성 가능한 입력으로 노출하고 싶지 않다면?
    - ex. 포트 번호 같은 건 의도치 않게 잘못 입력할 수 있다.
- 그렇다고 하드 코딩하기에는 유지보수가 어려움.
- `locals` 로 정의
    - 다른 모듈에는 영향 X
    - 외부에서 재정의 X

```bash
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
```

```bash
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}
```

- 참고로 정의할 때는 `locals` , 사용할 때는 `local`

## 4. 모듈 출력

- `module/output`에 출력하고 싶은 output 작성

```bash
output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
```

- `module.<MODULE_NAME>.<OUTPUT_NAME>` 으로 원하는 값 출력

```bash
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
	scheduled_action_name = "scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"
	autoscaling_group_name = **module.webserver_cluster.asg_name**
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
	scheduled_action_name = "scale-in-at-night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"
	autoscaling_group_name = **module.webserver_cluster.asg_name**
}
```

- 모듈에서 정의한 `output` 을 사용자에서 사용할 수도 있다.

```bash
# module/.../output.tf 
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
```

```bash
# stage/.../output.tf
output "alb_dns_name" {
  value       = **module.webserver_cluster.alb_dns_name**
  description = "The domain name of the load balancer"
}
```

## 5. 모듈 주의 사항

### 1. 파일 경로

- `file` 함수를 사용할 때는 파일 경로가 상대 경로여야 함.

```bash
data "template_file" "user_data" {
		template = file("user-data.sh") # 렌더링할 문자열
		vars = {                        # 사용할 변수
			server_port = var.server_port
			db_address = data.terraform_remote_state.db.outputs.address
			db_port = data.terraform_remote_state.db.outputs.port
	}
}
```

- 루트 모듈(=현재 작업 디렉터리의 모듈)에서 `file` 함수를 실행하는 것은 가능하지만, 별도의 폴더에 정의된 모듈에서 이를 실행할 수는 없음
- `path.module` : 표현식이 정의된 모듈의 파일 시스템 경로
- `path.root` : 루트 모듈의 파일 시스템 경로
- `path.cwd` : 현재 작업 중인 디렉터리의 파일 시스템 경로

```bash
data "template_file" "user_data" {
		template = file("${path.module}/user-data.sh") # 렌더링할 문자열
		vars = {                        # 사용할 변수
			server_port = var.server_port
			db_address = data.terraform_remote_state.db.outputs.address
			db_port = data.terraform_remote_state.db.outputs.port
	}
}
```

### 2. 인라인 블록

- 모듈을 작성할 때는 항상 인라인 블록 대신 별도의 리소스로 분리해서 사용해야 모듈의 유연성을 가질 수 있다.
    - 아래의 예에서는 외부에서 사용자 정의 규칙을 추가할 수 있다.

```bash
# Bad Case!!
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

	ingress {
		from_port   = local.http_port
	  to_port     = local.http_port
	  protocol    = local.tcp_protocol
	  cidr_blocks = local.all_ips
	}

	egress {
		from_port   = local.http_port
	  to_port     = local.http_port
	  protocol    = local.tcp_protocol
	  cidr_blocks = local.all_ips
	}
}

# Good Case!!
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

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
```

```bash
# stage/.../main.tf
resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id

  from_port   = 12345
  to_port     = 12345
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

- `locals` 는 모듈 외부에서 재정의가 안된다고 했는데 사용자가 가져온 모듈에서 다시 resource로 정의하는 것은 덮어쓰기가 되는건가?

## 6. 모듈 버전 관리

- 스테이징과 프로덕션이 동일한 모듈을 가리키는 한 완벽한 격리 상태에서의 테스트가 불가능
- 각 환경에서 서로 다른 버전의 모듈을 사용하는 것이 적절
    
    ![스크린샷 2022-12-17 오후 5.01.41.png](4%20%E1%84%90%E1%85%A6%E1%84%85%E1%85%A1%E1%84%91%E1%85%A9%E1%86%B7%20%E1%84%86%E1%85%A9%E1%84%83%E1%85%B2%E1%86%AF%E1%84%85%E1%85%A9%20%E1%84%8C%E1%85%A2%E1%84%89%E1%85%A1%E1%84%8B%E1%85%AD%E1%86%BC%20%E1%84%80%E1%85%A1%E1%84%82%E1%85%B3%E1%86%BC%E1%84%92%E1%85%A1%E1%86%AB%20%E1%84%8B%E1%85%B5%E1%86%AB%E1%84%91%E1%85%B3%E1%84%85%E1%85%A1%20%E1%84%89%E1%85%A2%E1%86%BC%E1%84%89%E1%85%A5%E1%86%BC%E1%84%92%20d6e83260f7314f7a9a4722057255a843/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-17_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.01.41.png)
    
- 모듈의 `source` 에 로컬 파일 경로를 넣으면 환경 분리X
    
    ```bash
    module "webserver_cluster" {
      source = "../../../modules/services/webserver-cluster"
    } 
    ```
    
- 모듈의 코드를 별도의 깃 repo에 넣고 `source` 매개 변수를 해당 repo의 URL로 설정
    - 테라폼 코드를 2개의 repo에 분산
        - 모듈(modules)
        - 모듈을 사용하는 사용자(live)
    
    ![스크린샷 2022-12-17 오후 5.05.29.png](4%20%E1%84%90%E1%85%A6%E1%84%85%E1%85%A1%E1%84%91%E1%85%A9%E1%86%B7%20%E1%84%86%E1%85%A9%E1%84%83%E1%85%B2%E1%86%AF%E1%84%85%E1%85%A9%20%E1%84%8C%E1%85%A2%E1%84%89%E1%85%A1%E1%84%8B%E1%85%AD%E1%86%BC%20%E1%84%80%E1%85%A1%E1%84%82%E1%85%B3%E1%86%BC%E1%84%92%E1%85%A1%E1%86%AB%20%E1%84%8B%E1%85%B5%E1%86%AB%E1%84%91%E1%85%B3%E1%84%85%E1%85%A1%20%E1%84%89%E1%85%A2%E1%86%BC%E1%84%89%E1%85%A5%E1%86%BC%E1%84%92%20d6e83260f7314f7a9a4722057255a843/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-17_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.05.29.png)
    

```bash
# prod
git tag -a "v0.0.1" -m "First release of webserver-cluster"
git push --follow-tags

# stage
git tag -a "v0.0.2" -m "Second release of webserver-cluster"
git push --follow-tags
```

```bash
module "webserver_cluster" {
	source = "git@github.com:kgw7401/modules.git//webserver-cluster?ref=v0.0.2"
	cluster_name = "webservers-stage"
	db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
	db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
	instance_type = "t2.micro"
	min_size = 2
	max_size = 2
}
```

- 버전 관리
    - MAJOR: 호환되지 않는 API 변경시
    - MINOR: 이전 버전과 호환되는 방식으로 기능 추가시
    - PATH: 이전 버전과 호환되는 버그 수정시