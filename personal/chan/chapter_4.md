# How to Create Reusable Infrastructure with Terraform Modules
## 1. Module Basics
- 사실, Terrafome에서 한 폴더 안에 있는 Terrafoem 구성 파일들은 다 Module이다.
- 공통적으로 사용하는 코드들은 modules 하위에 놓고 다른 곳(staging, production 등)에서 해당 파일들을 불러오는 방식으로 사용한다.
- 중복되는 코드의 양이 줄게 된다.
```
module "<NAME>" {
  source = "<SOUCE>"
}
```
## 2. Module Input
- 일반 프로그래밍 언어의 함수의 parameter 처럼 module에도 input parameter가 존재한다.
```
variable "varable_name" {
  description = "description"
  type        = string
}
```
```
var.variable_name
```
```
module "test" {
  source = "../modules/services/webserver-cluster"
  
  variable_name = 2
```
## 3. Module Locals
- 변수화는 하고 싶은데 특정 모듈에서만 사용해서 다른 모듈에는 노출하고 싶지 않을 때 사용
```
locals {
  http_port = 80
}
```
```
local.http_port
```
## 4. Module Outputs
- 함수의 return값 처럼 module의 return 값 (module 이름 접근)
- resource 의 필수값을 module에서 가져온다.
```
#in module/~
output "asg_name" {
  value = aws_autoscaling_group_example.name
  description = "test"
}

#in prod/~
resource "test" "test" {
  autoscaling_group_name = module.webserver_cluster.asg_name
}

#in module/~
resource "aws_autoscaling_group" "example" {
   ...
}
```
## 5. Module Gotchas
### 1. File Paths
- 보통 상대경로를 사용하는데 상대경로의 위치가 파일과 terraform 실행 위치가 달라서 맞지 않는 경우가 발생하므로 path reference를 사용
- path.module: expression이 정의된 module의 파일 위치
- path.root: root module의 위치
- path.cwd: 현재 디렉토리의 위치(보통은 root와 같은데, 바뀔 수가 있음)
### 2. Inline Blocks
- 사용하지 말고 separate resource를 사용
## 6. Module Versioning
- 버저닝을 하기위해서 git의 tag등을 사용하여 참조하도록 함
```
module "webserver_cluster" {
  source = "git@github.com:repo/modules.git//webserver-cluster?ref=v0.0.2"
}
## 7. Conclusion
- 여러 모듈을 사용하여 유연하게 만들자
- 개인적으론 접근하기가 불편한 느낌
