# 챕터4

# 1) Module Basics

- 테라폼에서 모듈을 쓰는 이유는 각 배포 환경마다 미세하게 달라져야 하는 부분이 있을 때 각각의 리소스를 배포 환경마다 복붙하지 않고, 변화를 가해야 하는 부분을 변수화시키기에 용이하기 때문이다.
- Terraform에서는 폴더로 감싼 부분을 모듈로 볼 수 있다.
- 따라서 modules 폴더 내에는 모듈 정보만 추가하고, 각 배포 환경 별로 이러한 모듈을 바탕으로 리소스를 정의하는 형태가 바람직하다
- 이때 주의사항으로는 새로운 모듈을 추가하면 항상 `terraform init` 명령어로 초기화해줘야 한다

아래와 같은 형태로 모듈이 정의된 폴더 경로를 source로 제공하면 된다.

```json
module "<모듈명>" {
  source = "../../../modules/services/webserver"
}
```

# 2) Module Inputs

모듈에서 일부 변형을 가하고 싶은 부분은 variable로 정의할 수 있다. 

`module/variables.tf` 이라는 파일을 만들어서 모듈 내에서 변경을 가할 부분을 선언해주면 된다. 

예를 들면 cluster_name, db_remote_state_bucket, db_remote_state_key 등을 변ㅅ화 시킬 수 있음

variable로 정의된 값들은 `var.변수명` 으로 참조하거나, 문자열로 쓸 때는 `"${var.변수명}-alb"` 와 같은 형태로 치환해서 사용할 수 있다. 

variable을 정의하고 나면 module을 생성할 때 아래와 같이 `[variables.tf](http://variables.tf)` 에서 정의한 변수들의 값을 입력하면 된다. 

```json
module "모듈명" {
  source = "모듈 폴더 경로"

  cluster_name = "webservers-stage"
  db_remote_state_bucket = "버킷이름"
  db_remote_state_key = "버킷 키"
}
```

# 3) Module Locals

모듈 내에서만 사용 되고 외부에서는 access 하지 못하는 지역 변수를 만들고 싶을 수 있다. 이럴 때는 locals 블록으로 정의할 수 있다. 

이런 값들은 변수로 되어 있는 부분을 모듈 상단 부분에 한번에 정의해놓을 때 편리하다. 

```json
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
```

locals에 정의한 값들은 `local.<변수명>` 으로 참조해서 사용할 수 있다. 

# 4) Module Outputs

모듈 output은 생성된 모듈의 attribute 값을 다른 리소스에서 참조하여 사용하고 싶을 때 쓰면 된다. 

예를 들면 ASG의 이름을 다른 리소스에서 활용해야 한다면 `[outputs.tf](http://outputs.tf)` 에 autoscaling_group의 이름을 참조해서 모듈 외부로 열어둘 수 있다.

```json
output "asg_name" {
  value = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
```

이렇게 모듈의 output으로 정의된 값은 `module.<모듈명>.<output명>` 으로 사용할 수 있다. 

# 5) Module Gotchas

모듈을 사용할 때 두가지 Gotchas(놓치기 쉬운 부분? 유의점?)이 있다. 

## File Paths

모듈을 사용하기 전에는 프로젝트의 root path로부터의 상대 경로를 사용하면 됐었다. 하지만 모듈을 사용하게 되면, 매번 모듈의 경로를 지정하는 것도 만만치 않다. 

이를 해결하기 위해서 다음과 같은 변수를 지원함

- `path.module` : 모듈이 정의된 폴더의 경로
- `path.root` : 가장 상위 모듈의 경로
- `path.cwd` : 현재 실행되고 있는 current working directory의 경로. 일반적으로 이 값은 `path.root` 와 같지만 terraform apply를 루트가 아닌 다른 경로에서 실행하는 경우에는 달라질 수 있다.

이를 활용한다면 모듈과 자주 사용되는 `[user-data.sh](http://user-data.sh)` 와 같은 파일이 있다면, 모듈 폴더 내에 배치한 다음에 `path.module` 를 사용해서 참조할 수 있다. 

```json
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh"

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_State.db.outputs.port 
  }
}
```

## Inline Blocks

이전 예제에서는 모듈 내에 inline으로 리소스를 정의했었음. 하지만 모듈을 사용할 때 inline blocks과 separate resource를 함께 사용하면 에러가 발생하는 경우가 있음 

따라서 항상 separate한 리소스로 정의하는 것을 권장함. 그래야 module이 더 flexible하게 활용될 수 있다. 

# 6) Module Versioning

일반적으로 Production 환경과 Staging 환경은 같은 모듈 폴더를 참조하지만, 약간의 변경을 가하게 되는 순간 다음 apply 시점에 두 환경에 모두 영향을 줄 수 있다. 따라서 모듈의 정의와 모듈 활용을 디커플링 시키는 것이 바람직하며 이를 위해서 버저닝된 모듈을 사용하는 것을 추천한다.  

이걸 하는 방법은 모듈의 source 폴더 경로를 지정할 때 폴더 경로 외에도 Git URL을 정의할 수 있다. 이를 적용한다면, 크게 modules와 live 두가지 폴더(혹은 레포지토리)로 나누어서 moduels는 일종의 블루프린트로만 사용하고 live에는 실질적으로 배포된 것들을 정의하는 형태로 사용하는 것을 추천함 

아래와 같은 형태로 버전 태그를 붙이고 push 할 수 있다. 

```json
$ git tag -a "v0.0.1" -m "First release of webserver-cluster module"
$ git push --follow-tags
```

아래와 같이 github의 태그를 지정해서 모듈을 정의할 수 있음. 이때 ref 파라미터를 활용하는 것이 좋으며 branch는 기본적으로 항상 last commit을 가져오므로 태그를 활용하는 것이 더 바람직하다

```json
module "webserver_cluster" {
  source = "github.com/foo/modules//webserver-cluster?ref=v0.0.1"

  ..

}
```

그리고 tags 이름을 지정할 때는 **semantic versioning**을 활용하는 것을 추천한다. 

- `MAJOR` : incompatible API를 만들 때
- `MINOR` : add functionality in a backward-compatible manner
- `PATCH` : make backward-compatible bug fixes

Q. 여러 모듈이 있을 때 semantic versioning은 어떻게 적용될까? 

⇒ Need some test

Q. service 별로 다시 리소스를 정의하는게 좋을까? 

⇒ I need some advice

# 번외편 - dynamic한 리소스, 블록 정의하기

Q. 똑같은 리소스를 상황에 따라서 n개를 만들고 싶을 때는 어떻게 해야 할까? 

⇒ `count` 문법을 활용해서 변수의 정수값 만큼 생성할 수 있음 

Q. Object들의 리스트를 바탕으로 리소스를 복수개 생성하고 싶을 때는 어떻게 해야 할까? 

⇒ `for_each` 문법을 활용해서 object들을 iterate하면서 리소스 내에 변수로 주입할 수 있음 

Q. 리소스 내에 블록을 동적으로 생성하고 싶을 때는 어떻게 할까?

⇒ `dynamic` ~ `content` 문법을 활용해서 변수가 null이 아닐 때에만 블록이 정의되도록 주입할 수 있음

Q. Database 같은 것들은 모듈화 하는게 좋을까? 

⇒ I need some advice

# 번외편 - existing infra로부터 terraform state만들기

아래 가이드가 `terraform import` 명령어를 활용해서 existing infra로부터 terraform state를 만드는 법을 알려주고 있음 [(관련 가이드)](https://developer.hashicorp.com/terraform/tutorials/state/state-import)

`terraform plan -refresh-only` 명령어를 쓰면 현재 state 파일과 infra 사이의 변경을 read-only로 알 수 있음. 특히 infrastructure의 drift를 파악하기에 좋음

# 번외편 - 포맷팅 쉽게 하기

`terraform fmt -recursive` 명령어를 활용하면 책에 나온 것처럼 동일한 블록 혹은 리소스 내의 포맷팅을 예쁘게 해줌. ([관련 가이드](https://developer.hashicorp.com/terraform/cli/commands/fmt))

pre-commit hook에 등록해놓으면 commit 할 때마다 포맷팅된 버전으로 overwrite해주니 다시 commit 하면 됨. 오히려 pre-push 훅에 등록해놓고 overwrite된 거에 format 커밋 메시지까지 달아주는게 나을 수도?

```json
mv .git/hooks/pre-commit.sample .git/hooks/pre-commit 
nano .git/hooks/pre-commit 
적절한 곳에 terraform fmt -recursive 추가하기
```

조금 더 심화된 방법으로는 아래 자료를 참조해봐도 좋을 듯 (보안 규칙 모니터링과 자동화된 모듈 도큐먼테이션 생성을 원한다면)

> [Pre-Commit Hooks for Terraform](https://medium.com/slalom-build/pre-commit-hooks-for-terraform-9356ee6db882)

> [Terrateam](https://terrateam.io/blog/terraform-pre-commit-hooks)