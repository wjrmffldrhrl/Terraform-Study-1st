# What is DevOps

과거에는 소프트웨어 회사를 만들려면 아주 많은 하드웨어를 다뤄야 했다.  

소프트웨어를 작성하는 developers, 하드웨어 관리를 전담하는 operations 두 가지로 나뉘게 된다.


Dev 팀은 app을 만들어 ops 팀에게 전달한다. 
Ops 팀은 이것을 어떻게 배포하고 app을 실행할지 궁리한다. 
- 보통 이건 수동으로 진행됐다.  
- 이건 불가피했다. 왜냐하면 거의 모든 작업이 물리 장비에 업로드 하는 것이기 때문이다.
- 소프트웨어에서 수행하는 작업도 서버에서 수동으로 명령을 실행하는 경우가 많았다.

기업이 커지면서 이러한 작업은 문제가 발생했다.
- 서버에 수동으로 배포한다고 하면 서버가 늘어나면 이 작업은 점점 느려지고 고통스럽고 예측 불가능해진다.
- 이러면서 실수가 발생하고 snowflake server가 된다.
  - 미묘하게 다른 구성들


결국 많은 버그가 발생하고 장애는 더 자주 발생한다.
릴리즈하고 발생하는 문제에 피로를 느껴 릴리즈 주기를 점점 늘리게 된다.
모든 프로젝트를 머지할 때 아주 많고 엉망이된 conflict를 해결해야 한다.
누구도 release 브랜치를 안정화할 수 없다.

요즘엔, 큰변화가 일어나고 있다.
그들 소유의 데이터 센터를 관리하는 대신 많은 기업들이 cloud로 이동한다. 
- AWS, Azure, GCP와 같은 서비스의 이점을 챙기기 위해
hardware에 투자하는 대신 많은 ops 팀은 모든 시간을 소프트웨어에서 일하는데 보낸다.
- rack서버나 네트워크 케이블을 다루는 대신 많은 시스템 관리자들이 코드를 작성한다.

결과적으로 Dev, Ops팀은 거의 모든 시간을 소프트웨어에서 일을하고 두 팀의 차이가 흐릿해진다.  
아직 두 팀의 역할을 나누는것이 의미는 있지만, 두 팀이 더욱 함께 일해야 하는건 확실하다.
이것이 DevOps의 시작이다.

DevOps는 프로세스, 아이디어, 테크닉이다.
조금씩 차이는 있지만 이 책에서는 아래의 뜻으로 DevOps의 뜻을 통일한다.  

**The goal of DevOps is to make software delivery vastly more efficient.**

- merge 지옥에서 벗어나 코드를 지속적으로 통합하고 배포 가능한 상태로 유지해야 한다.
- 월 1회 배포에서 벗어나 매일, 1 commit 마다 배포가 가능해야 한다.
- 지속적인 outage와 downtime 대신 복원력, 자가 복구 시스템, 모니터링, alerting을 구성하여 해결하지 못한 문제를 파악해야 한다.

DevOps의 4가지의 주요 행동이 있다.
- culture
- automation
- measurement
- sharing

그 중 이 책은 automation 에 집중한다.
여기서 automation은 인프라 관리를 웹 페이지에서 몇 가지 클릭해서 하거나 수동으로 커멘드를 쉘에서 실행하는 것이 아닌 코드를 통해 하는 것이다.

이것을 Infrastructure as Code라고 한다.


# What is Infrastructure as Code

IaC의 기본적인 아이디어는 인프라를 정의, 배포, 수정, 삭제를 위해 코드를 작성하고 실행한다는 것이다.  

- 이것은 운영의 모든 측면을 소프트웨어로 취급하는 사고 방식의 중요한 변화이다.

DevOps의 중요한 점은 거의 모든 걸 코드로 관리할 수 있다는 것이다.  


5개의 IaC tool category에 대해 알아보자  
- Ad hoc scripts
- Configuration management tools
- Server templating tools
- Orchestration tools
- Provisioning tools


## Ad Hoc Scripts
예를 들어 `setup-web-server.sh` 라는 스크립트로 웹 서버를 구성할 수 있다.  

```sh
# Update the apt-get cache
sudo apt-get update

# Install PHP and Apache
sudo apt-get install -y php apache2

# Copy the code from the repository
sudo git clone https://github.com/brikis98/php-app.git /var/www/html/app

# Start Apache
sudo service apache2 start

```

ad hoc 스크립트의 장점은 유명하고 널리 사용되는 프로그래밍 언어를 사용해 코드를 작성할 수 있다는 점이다.  
- 단점 또한 같다 (ㅋㅋ)

IaC 도구는 간결한 API를 제공하지만 범용 프로그래밍 언어는 완전히 사용자 전용 코드를 작성해야 한다.  
- 커스텀 코드를 많이 작성해야 한다.
- 개발자가 고유한 스타일을 사용하고 다른 작업을 수행한다.

이러한 대량의 스크립트를 관리한다면 스파게티 코드를 계속해서 유지할 수 없다.

ad hoc script는 작은 작업에는 좋지만 모든 인프라를 코드로 관리하게 된다면 IaC 도구를 찾게 될 것이다.  



## Configuration Management Tools
Chef, Puppet, Ansible은 configuration management 도구들이다.
이들은 이미 존재하는 서버에 소프트웨어를 설치하고, 관리하는 용도로 디자인되었다.

예를 들어 web-server.yml 이라는 Ansible role이 있다.
```
- name: Update the apt-get cache
  apt:
    update_cache: yes

- name: Install PHP
  apt:
    name: php

- name: Install Apache
  apt:
    name: apache2

- name: Copy the code from the repository
  git: repo=https://github.com/brikis98/php-app.git dest=/var/www/html/app

- name: Start Apache
  service: name=apache2 state=started enabled=yes

```
bash script와 비슷하지만 ansible과 같은 도구만의 장점이 있다.  

- Coding conventions
    - Ansible은 문서, 파일 레이아웃, 명확하게 명명된 매개변수, 암호 관리 등을 포함하여 일관되고 예측 가능한 구조를 적용한다.
    - 모든 개발자들이 그들의 ad hoc script를 다른 방법으로 관리한다.
    - 대부분의 configuration management tool은 컨벤션을 통해 더 쉽게 코드를 관리할 수 있도록 한다
- Idempotence
    - ad hoc script를 한 번 실행하는건 쉽다.
    - ad hoc script를 여러번 실행해도 정확하게 동작하게 하는건 어렵다.
    - 몇 번을 수행해도 문제가 없는 코드를 멱등한 코드라고 한다.
    - bash script를 멱등하게 작성하려면 정말 많은 코드를 추가해야 한다.
    - Ansible은 이것을 보장한다.
- Distribution
    - Ad hoc scripts는 한 머신에서 실행되도록 디자인 되었다.
    - CM tools는 많은 서버에서 돌 수 있도록 디자인 되었다.


## Server Templating Tools

CM tool의 대안은 최근 인기가 높아지고 있는 Docker, Packer, Vagrant와 같은 서버 템플릿 도구이다.  

서버 탬플릿 도구는 OS의 software, file, 관련된 모든것의 완벽한 캡쳐본에 대한 이미지를 만든다.  
- 다른 IaC 도구를 이용해서 이런 이미지를 다른 서버에 설치할 수 있다.

image를 사용하는 도구는 크게 두 가지가 있다.
### Virtual machine
- vm은 컴퓨터 시스템 전체를 모방한다.
    - 하드웨어 포함
- hypervisor를 사용하여 CPU, memory, hd, network를 가상화한다.
    - VMware, VirtualBox, Parallels
- VM의 image는 hypervisor 위에서 가상화된 하드웨어만을 바라보므로
    - host 머신과 완전ㅇ히 독립시킬 수 있다.
    - 모든 환경에서 정확히 동일한 방식으로 실행된다.
- 다만, 모든 하드웨어와 OS를 가상화 해야 하므로 오버헤드가 크다.
    - cpu 사용량, memory 사용량, startup time
### Container
- OS의 user space를 모방한다.
    - 독립된 process, memory, mount point, network
- container engine위에서 어떤 container든 user space를 바라보도록 실행할 수 있다
    - host machine과 다른 container들로부터 완전히 독립시킬 수 있다.
- 모든 환경에서 똑같이 동작할 수 있다.
- 단점으로는 모든 container는 한 OS kernel과 hardware에서 동작하므로 VM 수준의 독립 수준과 보안을 달성하기 어렵다
- 다만, 커널과 하드웨어는 공유하므로 컨테이너는 더 빠르게 시작될 수 있고 CPU, Memory 사용량에도 오버헤드가 없다.  
![1_1.png](../images/1_1.png)


서버 템플릿 도구는 인프라의 불변성을 달성하기 위한 핵심 구성 요소이다.  
- 이 아이디어는 변수 값을 다시 변경할 수 없는 functional programming에서 영감을 받았다.  
- 무언가 업데이트 되어야 하는 경우 변수를 새로 만든다.
- 변수는 절대 변경되지 않으므로 코드에 대해 추론하기가 쉽다.

인프라 불변성의 아이디어도 비슷하다.
- 한 번 서버를 배포하고 나면 변화가 없도록 해야한다.
- 만약 업데이트해야한다면 새로 만든다.
- 그래야 어떤걸 왜 배포했는지 이해하기가 쉽다.


## Orchestration Tools
서버 템플릿 도구는 유용하지만 실제로는 아래 상황들을 따라야 한다.
- 하드웨어를 효율적으로 사용하도록 VM or container 배포
- 존재하는 fleet를 몇 가지 전략을 통해 배포해야 한다.
    - rolling deployment, blue-green deployment, canary deployment
- VM과 container의 상태를 모니터링 하고 비정상적인 것은 자동으로 교체해야 한다.
- 부하에 따라 VM or container의 수를 늘리거나 줄인다.
- 트래픽 분배
- VM and container간 통신  

이것들이 모두 orchestration tool의 영역이다.
- such as K8S, Marathon/Mesos, ECS, Swarm, Nomad



## Provisioning Tools
위에서 언급한 도구들은 서버에서 동작하는 코드를 정의하지만 provisioning tool은 서버 그 자체를 만든다.
- Terraform, CloudFormation, OpenStack Heat, Pulumi

사실 provisioning tool은 서버 뿐만 아니라 db, cache, lb, queeue, monitoring 등 대부분의 인프라를 구성할 수 있다.  

```
resource "aws_instance" "app" {
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  ami               = "ami-0fb653ca2d3203ac1"

  user_data = <<-EOF
              #!/bin/bash
              sudo service apache2 start
              EOF
}

```
위와 같은 terraform 코드는 provisioning과 server templating까지 수행한다.
![1_2.png](../images/1_2.png)


# What Are the Benefits of Infrastructure as Code?

왜 새로운 언어들과 도구를 배우고 관리할 많은 코드들을 가져와서 귀찮게 하는걸까?

이는 코드는 매우 강력하기 때문이다.

수동 작업을 코드로 변환하는 투자는, 소프트웨어를 배포하는 능력을 드라마틱하게 향상시킨다.

실제로 IaC와 같은 DevOps를 적용하여 200배는 더 주기적으로 배포하고 복원력은 24배 빨라졌다. 
- lead time은 2,555배 짧아졌다.


인프라를 코드로 정의하면 넓고 다양한 소프트웨어 엔지니어링 practice를 통해 소프트웨어 배포 프로세스를 개선할 수 있다.

### Self-service
- 대부분의 팀에서는 소수의 sysadmin이 코드를 배포한다
    - SPOF
- 이는 기업의 성장에 bottleneck이 된다.
- IaC를 도입하면 모든 배포 과정을 자동화 할 수 있다.
### Speed and safety
- 만약 배포 프로세스가 자동화되면 아주 빨라질 것이다.
- 자동화된 배포 프로세스는 한결같고, 반복할 수 있고 에러를 발생시킬 일이 거의 없다.
### Documentation
- 만약 인프라가 코드로 정의된다면 인프라의 상태는 소스 파일로 존재하기 때문에 읽을 수 있다.
- 즉, IaC가 문서 역할을 수행하는 것이다.
### Version control
- IaC 파일은 버전 관리가 가능하다.
- 인프라의 모든 기록을 관리가 가능하다는 것이다.
- 만약 어떤 문제가 발생하면 문제를 확인하기도 쉽고 되돌리기도 쉽다.
### Validation
- 인프라의 상태가 코드로 정의되면, 매번 코드 리뷰와 자동화된 테스트를 통해 유효한 인프라인지 파악할 수 있다.
### Reuse
- 재사용 가능한 모듈로 인프라를 구성하여 이후에 다시 사용할 수 있다.
### Happiness
- 재미없게 반복되는 수동 작업은 작업자를 불행하게 만든다.
- IaC를 통해 지루한 수동 작업에서 벗어날 수 있다.

# How Does Terraform Work?

terraform은 HashiCorp가 오픈소스로 개발하였고 go로 작성되었다.  
terraform으로 작성된 코드를 수행할 때 별도의 인프라나 다른걸 실행할 필요가 없는데, 이는 terraform binary가 하나 이상의 provider의 API를 호출하기 때문이다.  

```tf
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}

resource "google_dns_record_set" "a" {
  name         = "demo.google-example.com"
  managed_zone = "example-zone"
  type         = "A"
  ttl          = 300
  rrdatas      = [aws_instance.example.public_ip]
}
```

위와 같은 코드를 통해 AWS의 인스턴스를 gcp dns에서 연결하는 등 multiple cloud provider를 사용할 수 있다.  

terraform이 당신의 코드를 binary parse하여 코드에 명시된 cloud provide의 API call의 연결로 변환한다.  
- 그리고 이러한 호출을 사용자를 대신하여 최대한 효율적으로 만든다.  

만약 인프라에 업데이트가 필요하면 직접 서버에 수동으로 작업하는 것이 아니라, terraform 코드를 수정하고 테스트와 코드 리뷰를 통해 유효한지 체크하고 `terrafrom apply`를 수행하면 된다.  

> terraform이 다양한 cloud platform의 provider를 지원하기 때문에 한 코드로 다양한 서버에 배포가 가능한지 궁금해하지만 완벽히 똑같은 구성을 배포하는건 할 수 없다.  
> 다른 클라우드 플랫폼은 같은 형태의 인프라를 제공하지 않기 때문이다.

### Q
- What is outage?


# words  
- redundant : 낭비되는
- dedicate : 바치다 봉사하다
- cadence: 마침
- occasionally: 가끔
- mess: 엉망인 상태
- halt: 멈추다
- profound: 깊은, 엄청난
- taking place: 일어나다.
- distinction: 차이
- slightly: 약간, 조금의
- undergo: 겪다
- astounding: 경악스러운 믿기 어려움
- defect: 결함
- measurement: 측정, 측량
- comprehensive: 포괄적인
- treat:	다루다, 대하다
- aspect:	측면, 양상
- discrete:	별개의, 분리된
- concise:	간결한
- accomplishing:	수행하다, 해내다
- Idempotence:	멱등성
- alternative:	대안, 대체
- bunch:	송이, 다발, 묶음
- relevant:	관계가 있는
- contained:	억제하는, 침착한
- self-contained:	자족적인
- emulate:	모방하다
- drawback:	단점, 장애, 결점
- incurs:	초래하다, 발생시키다,
- inspire:	영감을 주다, 불어넣다
- realm:	왕국, 영역
- instructs:	지시하다, 가르치다
- aspect:	양상, 모양
- bother:	괴롭히다, 귀찮게 하다.
- incantations:	주문, 마법
- significantly:	상당히, 의미있게
- tedious:	실증나는, 지루한
- transparently:	명백히, 투명하게
