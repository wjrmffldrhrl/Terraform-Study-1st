# 왜 테라폼인가?

이번 챕터에서는 테라폼의 기본 사용법에 대해 배워봅시다. 원래는 회사에서 주로 사용하고 있는 GCP로 실습을 해볼까 했는데 오랜만에 AWS를 다시 사용해보고 싶기도 하고 책 실습을 따라가는게 맘 편하기도 해서 AWS로 하려고 합니다. GCP는 시간이 되면 나중에 따로 구성을 할까 싶습니다. (이러고 안할거지만...)

## 1. AWS 계정 설정

저는 가지고 있는 아이디는 모두 프리티어 기간을 다 소진해버려서 다시 새로 아이디를 팠습니다. 갑자기 야후가 생각나서 오랜만에 야후 메일을 새로 만들어봤습니다.

아이디 생성을 했으면 가장 먼저 보안을 위해 IAM부터 설정해보도록 하죠. IAM은 Identity and Access Management의 줄임말로, 사용자 계정 및 각 사용자의 권한을 관리하는 서비스입니다. 생성하는 방법은 아주 쉬운데, IAM 콘솔로 들어가서 [사용자] -> [사용자 추가] -> [권한 설정]만 하면 됩니다.

그리고 마지막에 CSV 파일을 다운받아 안전하게 보관해주면 기본적인 AWS 설정은 모두 끝이 납니다.

## 2. 테라폼 설치

테라폼을 설치해볼 시간입니다. 홈페이지에서 zip을 다운받을 수도 있고 편리하게 터미널로 다운받을수도 있습니다. 저는 맥북을 이용하고 있어서 `brew install terraform`으로 편리하게 다운받도록 하겠습니다. 잘 다운받아졌는지 확인해보려면 터미널에 `terraform`을 쳐보면 알 수 있습니다.

이제 테라폼이 AWS를 이용할 수 있도록 해주어야 합니다. 아까 IAM을 설정할 때 CSV을 받았을텐데 거기에 있는 ACCESS_KEY와 SECRET_KEY가 있을겁니다. 이들을 환경변수로 등록해주어 테라폼이 이를 이용할 수 있도록 해줍니다.

```bash
export AWS_ACCESS_KEY_ID=(...)
export AWS_SECRET_ACCESS_KEY=(...)
```

참고로 export는 새로운 터미널에서는 리부트된다는 점 기억하자!

## 3. 단일 서버 배포

테라폼은 HashiCorp사에서 만든 확장자가 .tf인 **HCL**라는 선언형 언어로 코드를 작성합니다. 앞에서도 설명했듯이 선언형 언어이기 때문에 코드를 작성해두면 테라폼이 이를 보고 원하는 인프라 상태를 구성해줍니다. 그러면 테라폼 코드를 한 번 작성해볼까요?

가장 먼저 공급자를 구성해보죠. `main.tf` 파일에 다음과 같은 내용을 작성해봅시다.
```
provider "aws" {
  region = "ap-northeast-2"
}
```
가장 먼저 어디에 만들지를 작성해보죠. 깊게 생각하지 않아도 대충 무슨 코드인지 알거 같은데, AWS 공급자를 사용하여 ap-northeast-2(서울)에 무언가를 생성하라는 코드같네요. 어디에 생성할지를 정했으니 여기에 무엇을 만들 것인지도 작성해줘야겠죠?

resource는 `"PROVIDER_TYPE" "NAME"`로 공급자, 생성할 리소스 유형, 식별자를 지정해줍니다. 그리고 {}에 이에 해당하는 인수들을 채워주면 됩니다.

아래 코드를 해석해보면 aws에 instance를 example이라는 이름으로 생성하는데, 이 instance는 ami-0c55b159cbafe1f0라는 이미지(ubuntu 18.04)로, 인스턴스 유형은 t2.micro로 설정하여 구성합니다.
```
resource "aws_instance" "example" {
  ami = "ami-068a0feb96796b48d"
  instance_type = "t2.micro"
}
```
참고로 각 리소스에 해당하는 인수들을 다 외우는 것은 거의 불가능함으로 구성할 때 테라폼 문서를 수시로 참고하여 구성해주면 됩니다.

이제 `terraform init` 명령으로 테라폼이 기본적인 세팅을 할 수 있도록 해줍니다. 테라폼을 처음 깔면 기본적인 기능은 포함되어 있지만 각 공급자에 대한 코드가 모두 포함되어 있지는 않기 때문에 init 명령을 통해서 테라폼이 코드를 한 번 훑고 필요한 도구들을 다운받을 수 있도록 해줍니다.

공급자 코드를 다운로드 했으니 `terraform plan`을 실행해보죠. 이름만 봐도 대강 알 수 있듯이 실행하기 전에 테라폼이 수행할 작업을 확인할 수 있습니다. 일종에 테스트 같은 건데요. 실제 운영환경에 적용하기 전에 코드에 오류가 없는지 한 번 검새를 해줍니다. 개인적으로는 개발할 때 컴파일이나 airflow의 `airflow dags test`와 비슷한 기능을 할 수 있다고 느껴졌습니다. 첵에서는 `git diff`와도 비교했는데 plan을 통해 어떤 항목이 추가되고 빠지는지도 알 수 있기 때문입니다.

plan과 비슷한 `terraform apply`도 있는데요. apply를 실행해보면 터미널에 plan과 똑같은 결과가 나옵니다. 하지만 하나 다른 점은 마지막에 해당 plan을 실행할 것이냐는 메시지도 함께 나온다는 것인데요. apply 명령어를 통해 plan도 확인하고 바로 실행하여 결과를 볼 수 있습니다.

EC2 콘솔에 가서 확인해보니 생성이 되었네요. 저의 인생 첫 테라폼을 이용한 EC2 생성 아주 뿌듯하군요.

이제 몇가지 옵션들을 더 추가해줘보겠습니다. 이 인스턴스에 이름을 한 번 부여해보죠.

```
resource "aws_instance" "example" {
  ami = "ami-068a0feb96796b48d"
  instance_type = "t2.micro"

  tags = {
    Name = "terrform-example"
  }
}
```

그리고 다시 `terraform apply`를 해볼까요. 처음 apply를 했을 때와는 조금 다른 결과가 나오는데요. 계속 언급했듯이 테라폼은 선언형이기 때문에 이전의 상태를 기억하고 이를 바꿔줍니다. 그래서 첫번째 이후로 apply를 하게 되면 이전의 상태와 비교하여 tf에서 작성한 새로운 상태로 맞춰나가는 것이죠. 다시 EC2 콘솔을 보면 태그가 잘 생성된 것을 볼 수 있습니다. 작성한 코드는 git에 올려서 저장하도록 합시다.

## 4. 단일 웹 서버 배포

인스턴스를 띄워보았으니 이제 인스턴스에 웹 서버를 배포해봅시다. 사용자의 HTTP 요청에 응답하는 아주아주 간단한 웹 서버를 띄워볼겁니다.

```bash
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
```

해당 배시 스크립트를 간단하게 설명해보면 index.html에 Hello, World를 저장하고 이를 busybox를 이용하여 8080 포트에서 띄우는 코드입니다.

이 스크립트를 실행하려면 패커와 같은 도구로 웹 서버가 설치된 사용자 지정 AMI를 생성하면 됩니다. 하지만 이 임시 웹 서버는 EC2 인스턴스의 user_data를 설정하여 인스턴스가 시작될 때 명령어를 사용자 데이터에 전달하여 작업을 수행할 수 있습니다.

사실 이번에 EC2에 user_data라는 기능이 있는 걸 처음 알았는데, 찾아보니 EC2가 생성되면서 실행되는 스크립트이고  첫 부팅될때만 실행된다고 하더라구요. 엥? 그런데 분명 저희는 이미 인스턴스를 생성하고 그 뒤에 테라폼으로 다시 재실행을 해준 것인데 어떻게 user_data가 적용되는 걸까요?

이유는 아주 간단한데, 바로 apply 명령을 하면 테라폼이 인스턴스를 새로운 것으로 교체하기 때문입니다. 1장에서도 언급됐지만 테라폼은 기본적으로 불변 인프라이기 때문에 '변경'은 완전히 '새로운 서버'를 배포하는 것과 같습니다. 이 때문에 user_data를 이용할 수 있는 것이죠. 하지만 완전히 새로운 서버를 배포하는 것이기 때문에 사용자들은 서비스 중단을 경험하게 되는데, 테라폼에는 중단없이 배포하는 방법도 있다고 합니다.

기본적으로 EC2는 보안때문에 인앤아웃 트래픽을 허용하지 않습니다. 그래서 8080 포트로 HTTP 요청을 주고 받을려면 따로 설정을 해주어야 합니다.

```
resource "aws_security_group" "instance" {
  name = "terrform-example-instance"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

아직 끝이 아닙니다. 보안 그룹을 설정했으면 이제 이 보안 그룹을 EC2가 사용할 수 있게끔 인수로 지정해주어야 합니다. 그러기 위해서는 표현식을 살펴봐야 합니다. 테라폼에는 다양한 표현식이 있는데, 지금 쓰일 것은 코드의 다른 부분에서 값에 엑세스할 수 있게 해주는 `참조`에 대해서 알아볼 것입니다. 참조는 계속 써왔던 것인데, 형식은 `<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>`입니다. 계속 봐왔던 형식이죠?

이를 이용하여 인스턴스에서 `vpc_security_group_ids`라는 인수로 아까 설정한 보안그룹의 ID를 사용할 수 있습니다.

```
resource "aws_instance" "example" {
  ami = "ami-068a0feb96796b48d"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "terrform-example"
  }
}
```
지금 instance라는 리소스에서 security_group를 참조하고 있는데, 이러면 종속성이 생기게 됩니다. 테라폼에서는 이러한 종속성을 분석하여 그래프를 작성하고 리소스를 생성하는 순서를 자동으로 결정합니다. 여기서는 보안그룹이 생성되어야 인스턴스가 이를 참조할 수 있으니 보안 그룹을 먼저 생성해야 되는 것처럼 테라폼은 이런 종속성을 신경써서 최대한 효율적이고 병렬적으로 인프라를 구성해줍니다.

이런 종속성은 `terraform graph`를 통해 알 수 있고, 다양한 라이브러리를 통해 쉽게 시각화할 수도 있습니다.

새로 구성한 코드를 apply로 다시 배포해보죠. 몇 초 정도 기다리면 새로운 서버가 배포됩니다. 잘 동작하는지 확인해볼까요? `curl http://<PUBLIC_IP>:8080`으로 명령을 날리면

## 5. 구성 가능한 웹 서버 배포

현재 구성에는 8080 포트가 여러 곳에 중복되어 있습니다. 하지만 이는 DRY 원칙을 위배하게 됩니다. 따라서 코드 내에서 모든 지식은 유일하고, 모호하지 않으며, 믿을 만한 형태로 존재해야 합니다. 쉽게 말하면 한 곳에서 무언가를 변경하면 다른 곳은 신경쓰지 않아도 되게끔 해야한다는 것입니다. 테라폼에서는 이를 변수로 정의하여 관리할 수 있게 해줍니다. 형식은 다음과 같습니다.

```
variable "NAME" {
  [CONFIG ...]
}
```

본문에는 3가지 매개 변수가 포함될 수 있습니다. 바로 예시를 보도록 하죠.
```
variable "map_example" {
  description = "An example of a map in Terrform"
  type = map(string)

  default = {
    key1 = "value1"
    key2 = "value2"
  }
}
```

`description`은 해당 변수의 설명이고, 중요한 것은 `type`과 `default`인데요. `type`은 해당 변수의 변수 타입을, `default`는 테라폼에 변수로 값이 전달되지 않았을 때 기본으로 적용되는 변수값입니다.

이번 웹서버 예제의 경우는 포트 번호를 지정하는 변수만 있으면 됩니다.
```
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}
```

바로 명령에서 변수를 전달해주려면 `terrform plan -var "server_port=8080` 명령어를 입력하면 됩니다. 환경변수로 전달하고 싶다면 `TF_VAR_<variable_name>`으로 export를 해주면 됩니다. 만약 `default`가 없어서 그냥 apply를 하면 변수를 입력하라는 명령어가 나오는데 이떄는 터미널에서 바로 변수를 입력해주면 됩니다.

테라폼 코드에서 입력 변수의 값을 사용하려면 변수 참조라는 표현식을 사용하면 되는데요. 포맷은 `var.<VARIABLE_NAME>`입니다. 예를 들어 보안 그룹에서 포트 번호를 변수 참조로 참조하고 싶다면 다음과 같이 사용하면 됩니다.

```
resource "aws_security_group" "instance" {
  name = "terrform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

user_data에도 똑같이 변수를 사용해주는 것이 좋은데, 여기에는 보간이라는 표현식을 사용하면 됩니다. `${...}`

```
user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF
```

마지막으로 테라폼에서는 위와 같은 입력 변수뿐 아니라 출력 변수도 정의할 수 있습니다. 예를 들어 설정한 인스턴스의 퍼블릭 IP를 제공하고 싶다면 다음과 같이 지정할 수 있습니다.

```
output "public_ip" {
  value = "aws_instance.example.public_ip"
  description = "The public IP"
}
```
위에는 없지만 만약 보안에 민감한 데이터라 출력에 기록해두지 않고 싶다면 `sensitive = true`로 매개변수를 추가하면 됩니다. `terraform output` 명령을 이용하면 현재 사용되는 output을 나타낼 수도 있고 특정 값을 알고 싶다면 뒤에 변수명을 붙여 `terrform output public_ip`를 입력하면 값을 알 수 있습니다.

## 6. 웹 서버 클러스터 배포

단일 서버는 많은 트래픽이 몰리면 사이트가 터져버립니다. 그래서 여러 서버로 클러스터를 구성해서 트래픽을 분산시키고, 양에 따라 클러스터 크기를 늘리거나 줄이면 좋겠죠. 이런 작업은 수동으로 하기에는 손이 굉장히 많이 가기 때문에 자동으로 관리해 줄 수 있는 툴을 사용해주면 좋습니다. AWS에는 ASG라는 오토스케일링 서비스가 있어서 EC2 클러스터의 시작, 상태 모니터링, 사이즈 조정 등 많은 작업을 동시에 처리합니다.

ASG를 만드는 첫단계 각 EC2 인스턴스를 어떻게 구성할 것인지 configuration을 설정해야 합니다. `aws_launch_configuration`라는 리소스를 이용하면 되는데, 설정은 앞에서 보았던 인스턴스 설정과 완전히 동일합니다.

```
resource "aws_launch_configuration" "example" {
  ami = "ami-068a0feb96796b48d"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}
```

그리고 `aws_autoscaling_group` 리소스를 사용하여 ASG 자체를 생성할 수 있습니다.

```
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
```

그런데 여기서 문제가 하나 있습니다. 테라폼은 리소스를 교체할 때 이전 리소스는 삭제하고 새로운 리소스를 생성합니다. 만약 해당 리소스가 다른 리소스를 참조하고 있다면 이를 삭제할 수가 없습니다. 저는 DB가 생각났는데요. DB에서도 한 테이블이 다른 테이블을 참조하고 있다면 삭제를 했을 때 오류가 발생합니다.

이 문제를 해결하기 위해 수명 주기 설정을 할 수 있습니다. 테라폼은 리소스 생성, 업데이트 삭제와 관련된 수명 주기를 지원합니다. 여기서는 `create_before_destroy`를 사용해야 하는데요. 이를 `true`로 설정하면 새로 생성할 ASG를 먼저 생성하고, 이 후에 기존에 있던 ASG를 삭제합니다. 이렇게 되면 교체할 리소스가 다른 리소스를 참조하고 있어도 문제가 없습니다.


```
resource "aws_launch_configuration" "example" {
  ami = "ami-068a0feb96796b48d"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}
```

ASG에 추가해야 하는 매개변수에는 `subnet_ids`도 있습니다. `subnet_ids`은 ASG가 EC2를 어느 VPC 서브넷에 배포할지 지정하는 매개변수로, 각 서브넷은 분리된 데이터 센터에 있으므로 인스턴스를 여러 서브넷에 배포하면 무중단 운영이 가능합니다.

서브넷 목록은 데이터 소스를 사용하여 얻을 수 있습니다. 데이타 소스는 테라폼을 실행할 때마다 공급자에서 가져온 읽기 전용 정보를 나타냅니다. 단순히 GET으로 데이터를 가져오기만 한다고 생각하면 될 거 같고 여기에는 VPC 데이터, 서브넷 데이터, AMI ID, IP 주소 범위 등이 있습니다.


바로 예시를 살펴보면, 아래는 먼저 vpc 데이터 소스에 `default=true`라는 필터를 이용하여 기본 vpc를 찾도록 합니다. 이처럼 데이터 소스에서의 인수는 일반적으로 필터로서 기능하는 경우가 많습니다.

또한 여기서도 참조를 할 수 있는데요. subnet_id가 vpc의 id를 참조하여 해당 vpc 내의 subnet_id를 가져올 수 있도록 하였습니다.
```
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
```

이를 이용하여 데이터 소스에서 서브넷 ID를 가져와 ASG가 이를 사용하도록 지시할 수 있습니다.

```
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
```

## 7. 로드 밸런서 배포

지금은 서버가 여러 대 있는 상태이기 때문에 IP 주소 또한 각 서버마다 여러 개가 있는 상황입니다. 하지만 사용자는 하나의 IP를 통해 접속하기를 원할텐데 이를 위해 로드 밸런서를 배포하여 트래픽을 분산시키면서 사용자가에게 하나의 IP만 제공할 수 있도록 합니다. 아마존에서는 ELB라고 하는 서비스를 통해 이를 처리할 수 있습니다.

ELB도 여러 종류가 있는데, 지금은 ALB를 사용할 예정입니다. 이를 구성하려면 여러 단계가 필요한데 바로 첫번째 단계의 코드부터 볼까요.

먼저 ALB 자체를 생성해야 합니다. 아래에서 볼 수 있듯이 type은 ALB를 의미하는 `application`으로 설정하고, subnets은 기본 vpc의 모든 서브넷을 사용합니다. 참고로 ELB는 별도의 서브넷에서 실행될 수 있는 여러 서버로 구성되어 있습니다.

```
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
}
```

두번째 단계는 리스너를 정의하는 것입니다. 이 리스너는 HTTP 포트인 80번을 수신하고, 프로토콜은 HTTP를 사용하고, 규칙과 일치하지 않는 요청에 대해 404를 보냅니다.

```
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code = 404
    }
  }
}
```

ALB도 인앤아웃 트래픽을 허용하지 않으므로 이 또한 보안 그룹을 설정하여야 합니다. 그리고 이를 ALB 리소스가 이용할 수 있도록 설정해주어야겠죠.

```
resource "aws_security_group" "alb" {
  name = "terrform-example-alb"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}
```

다음은 `aws_lb_target_group` 리소스를 이용하여 대상 그룹을 설정해야 합니다. 이 대상그룹은 각 인스턴스에 주기적으로 HTTP 요청을 전송하여 헬스 체크를 합니다. `matcher`를 통해 원하는 응답값을 지정할 수 있고, 만약 지정한 threshold 만큼 원하는 응답값을 받지 못하면 트래픽 전송을 자동으로 중단합니다.

```
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol  = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healty_threshold = 2
    unhealty_threshold = 2
  }
}
```

그러면 설정한 대상 그룹을 어느 EC2 인스턴스에 보낼지 어떻게 알 수 있을까요? 이는 `aws_lb_target_group_attacement` 리소스를 사용하여 EC2 정적 목록을 사용할 수 있습니다. 하지만 ASG는 언제든 인스턴스의 상태를 변화시킬 수 있기 때문에 정적이라면 작동하지 않을 수 있습니다. 대신 ASG와 ALB를 통합하여 사용할 수 있는데요. ASG 리소스에서 `target_group_arns` 인수를 설정하여 새 대상 그룹을 지정합니다.

health_check도 ELB로 설정하는데 기본값은 EC2입니다. EC2는 인스턴스가 완전히 터져버렸을때만 비정상이라고 간주하는데, 이렇게 하면 아까 지정한 대상 그룹 상태 확인 설정대로 인스턴스 동작을 확인할 수 있습니다.(응답값이 200이 아닐때)
```
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
```

마지막으로 `aws_lb_listener_rules` 리소스를 사용해 리스너 규칙을 생성하여 이 모든 부분을 연결합니다. `action`은 라우팅에 대한 설정으로 대상 그룹과 유형을 설정합니다. `condition`은 지정한 value와 일치하는 주소에 대한 조건문입니다. 여기서는 모두 허용해주었네요.
```
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
```

드디어 ASG를 배포하기 위한 모든 준비가 끝났습니다. `terraform apply`로 실행하면 끝인데 저는 처음에 권한 오류가 떠서 실패했습니다... 근데 웃긴건 다시 실행하니까 또 되더라구요. 이유는 모르겠지만 성공적으로 생성을 완료했습니다.

완료가 되고 EC2 콘솔로 가면 성공적으로 2개의 EC2 인스턴스가 생성된 것을 볼 수 있습니다. 그리고 output으로 나왔던 dns 주소로 curl 명령을 보내면 접속이 잘 되는지도 확인할 수 있습니다.

## 8.정리

이제 모든 리소스를 제거해야 됩니다. 제거하지 않으면 요금 폭탄을 맞을 수도 있기 때문에 중요합니다. 이는 `terraform destroy`를 이용하여 간단하게 정리할 수 있습니다.
