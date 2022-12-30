# CH1. Why Terraform-prod

태그: IaC, Terraform, 스터디, 책

# Ch1. 왜 테라폼을 써야할까?

소프트웨어는 실제로 유저가 사용하기 전까지 개발이 완료된게 아니다.

소프트웨어 배포 과정은 문자 그대로 유저가 해당 소프트웨어를 사용할 수 있게 만드는 모든 과정을 포함하고 있다.

프로덕션 서버에서 코드가 작동되게 하고, 서버의 가용성, 해커로부터 서버 보호하기등.

여튼 테라폼 이해하기전에 소프트웨어 배포과정에 대해 조금 더 알아보자

## 1. DevOps란?

예전 보통의 소프트웨어 회사에서는 지금처럼 클라우드 서비스를 이용하지 않고 서버실 따로 만들어서 서버를 관리. 그래서 개발팀(Dev)은 소프트웨어 코드들 작성하는 팀과 운영팀(Ops)은 하드웨어를 관리하는 팀으로 나눠져있는게 아다리가 맞음.

따라서 개발팀에서 어플리케이션 코드를 운영팀에 전달하면 운영팀은 이 코드를 어떻게 배포하고 계획하고 실행했는데 여기서 문제가 발생.

당시에는 매뉴얼적으로 운영팀에서 배포를 했기에 서버가 작았을 땐 괜찮았지만 관리하는 서버가 많아질수록 각 각의 서버에 조그씩 다른 환경 설정 차이가 발생한것. (이를 snowflake server라고하는듯요.) 버그도 많아졌고 개발팀에서는 “제 컴퓨터에서는 되는데요?”를 시전. 

하지만 요즘에는 온프레마이스가 아닌 클라우드 서버를 많이 사용해서 직접 서버를 운영하는 곳은 많지 않다. 그래서 운영팀은 이제 하드웨어를 관리하는게 아니라 Ansible, Docker, Terraform과 같은소프트웨어를 이용해 어플리케이션을 배포.

이제는 개발팀이나 운영팀 모두 코드를 작성하고있고 둘 경계가 희미해졌다. 이게 바로 DevOps 움직임의 시작!

DevoOps는 팀이름은 이나 직업 타이틀이 아니고 단지 소프트웨어를 효율적으로 배포하는 것을 목적으로 한 하나의 프로세스로 자리 잡게 되는데..

DevOps가 중요하게 생각해야하는 걸 줄여서 CAMS라고 칭함.

1. culture  문화
2. automaiton 자동화
3. measurement
4. sharing  공유 

## 2. IaC란?

코드로 인프라(서버, 데이터베이스, 네트워크, 로그파일등)를 배포, 수정, 삭제하는 것(거의 모든 것 관리)을 의미. IaC 툴로는 크게 5가지 종류가 있다.

1. Ad hoc scripts 에드 혹 스크립트
2. configuration mgmt tools 설정관리툴
3. server templating tool 
4. 오케스트레이션 툴
5. 프로비저닝 툴

### 2-1. ad hot scripts 에드혹스크립트

무엇이든 자동화 하기 가장 편한 방식은 아래와 같은 에드 혹 스크립트라고 저자가 그럼.  bash, 루비, 파이썬등 선호하는 언어 통해서 서버 배포 과정을 코드로 작성하고 서버에서 실행할 수 있게함.

아래는 웹서버 의존성 설치하고 아파치 웹서버를 실행시키는 스크립트(setup-webserver.sh)

```
# Update the apt-get cache
sudo apt-get update

# Install PHP and Apache
sudo apt-get install -y php apache2

# Copy the code from the repository
sudo git clone https://github.com/brikis98/php-app.git /var/www/html/app

# Start Apache
sudo service apache2 start
```

장점 

- 사람들이 자주사용하는 거를 보통 사용함
- 가장 간단함. 소규모 일회성 작업에 적합
- 단점
    - 사용자가 수동으로 맞춤 코드를 작성해야 한다
    - 범용 프로그래밍 언어는 사용자마다 고유한 스타일이 있음
    - 만약에 큰 레포지토리 내의 인프라를 에드혹 스크립트로 관리하게 될 경우 스파게티 코드가 될 가능성이 있음(예제에서야 4줄이지만)
    

### 2-2. configuration management tool  설정관리툴(Ansible같은)

이미 존재하고 있는 서버에서 sw를 설치하고 관리하기 위해 사용되는 있는 도구들을 설정관리 툴이라고 부른다. chef, puppet, ansible, saltsat등

아래는 첫번째 에드혹 스크립트를 앤서블로 작성한 내용이다.

```
#  ansible setup-webserver.sh
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

방금전 에드혹스크립트랑 이랑 비슷하지만 아래와 같은 장점있음.

- 코딩컨벤션이 정해져있다. (파일 레이아웃, 파라미터등)
- 멱등성(여러번실행해도 결과 같은놈은 알아서 스킵)
- 분산
    - 에드혹스크립트 하나는 하나의 머신에서만 실행되게 되어있지만 설정관리툴은 매개변수를 설정하여 롤링 배포를 수행하거나 병렬 수행 카운트를 지정할 수도 있다(여러개의 서버대상으로 배포가능)

### 2-3. servertemplating tool(Docker같은)

설정관리 대안으로는 servertemplating tool이 있다. (docker, packer, vagarant)

여러개의 서버를 런칭한 후에 같은 코드를 각 각의 서버에서 실행시키는게 아니라  OS, 실행되어야 하는 서버 파일 및 관련 환경변수등을 하나의 스냅샷으로 만들 수 있게 servertemplating tool이 도와준다.

한편 이미지관련해서 두개의 카테고리있음

- virtual machine (VM) → vm이 컴퓨터 시스템 전체를 에뮬레이팅함. vmware, virtualbox, parallers. 근데 오버헤드가 많음
- containers : OS만 에뮬레이팅함

사실 Packer(Docker같은놈인듯) template이 에드혹스크립트와 같은 역할을 하지만 Packer 코드에서는 `sudo service apache2 start` 같이 실제로 아파치 웹서버를 실행시키지 않음. 왜냐면 이미지안에는 이미 아파치가 깔려잇는데 실제로 이미지를 실행시키는(컨테이너로)때에 서버가 실행되므로.

- 서버 템플릿은 불변 인프라로 전환하는 데 있어 핵심적인 구성 요소
- 한번 배포된 서버는 다시 변경되지 않는다. 새 버전의 코드를 배포하는 것과 같이 서버를 변경해야 하는 경우 새 이미지를 만들어 배포해야 한다.

### 2-3. orchestration tool(k8s같은)

server templating으로 vm이나 컨테이너 만든는 건 좋은데 수십개의 컨테이너를 어떻게 관리하나?  서버 템플릿 도구는 유용하지만 실제로는 아래 상황을 처리   할 수 있어야한다. 

K8S, Marathon/Mesos, ECS, Swarm, Nomad

- 하드웨어를 효율적으로 사용하도록 VM or container 배포
- 존재하는 fleet를 몇 가지 전략을 통해 배포해야 한다.
    - rolling deployment, blue-green deployment, canary deployment
- VM과 container의 상태를 모니터링 하고 비정상적인 것은 자동으로 교체해야 한다.
- 부하에 따라 VM or container의 수를 늘리거나 줄인다.
- 트래픽 분배
- VM and container간 통신

이것들이 모두 orchestration tool의 영역이다.

### 2-4. provisioning tools(Terraform같은)

프로비저닝 툴로는 `OpenStack Heat`, `Terraform`, `CloudFormation`등이 있는데 이러한 것들은 서버를 만드는 책임을 갖고 있고 서버 만드는 것 뿐만 아니라 데이터베이스, 캐시, 로드밸런서, 큐, 모니터링, 서브넷 설정, 방화벽 설정, 라우팅 룰,  SSL 인증서등 다양한 인프라스트럭처를 구성할 수 있게 해준다.

다음은 테라폼을 이용해 웹서버를 배포하는 코드이다.

```
# Terraform configuration

resource "aws_instance" "app" {
	instance_type = "t2.micro"
	availability_zone = "us-east-2a"
	ami = "ami-0c55b159cnfafe1f0"
	user_data = <<- EOF
		   #! /bin/bash
		   sudo service apache2 start
		   EOF
}

```

이 코드는 프로비저닝과 서버 템플릿이 같이 보여주고 있고 이러한 패턴은 immutable infrastructure에서 자주 보인다.
terraform configuration -> terraform -> cloud provider(aws등에서 db, 캐시, 로드밸런스등 인프라스트럭처의 다양하 ㄴ파트에서 쓰일 수 있음)

- `ami` : 서버에 배포할 AMI ID 지정. 이 파라미터는 `web-server.json` Packer 템플릿섹션에서
- `user_data` : 이 배쉬 스크립트는 웹서버가 부팅 될 떄 실행된다. 예제에서의 코드는 아파치 boot up을 위한 코드입

## 3. IaC툴 쓰면 좋은점

- self-service : 한명의 인프라 관리자가 모든걸 진행하는게 아니라 다른 개발자들도 인프라가 코드로 작성되어있으면 배포과정도 자동화 가능
- speed and safety
- documentation : IaC 그자체가 인프라 어떻게 구성하는지에 대한 문서가 될 수 있음
- version control : 깃과 같은 버전 컨트롤에 코드 보관 가능하고 커밋 로그 확인가능할 수 있음.
- validation : IaC에 대한 테스크코드 작성하므로 결함 확인 가능
- reuse : 내가 구성한 인프라 관련 코드에서 중복되는게 많다면 모듈로 관리할 수 있음
- happiness

## 4. 테라폼은 어떻게 작동하나?

테라폼은 오픈 소스 툴로 `HarshiCorp` 에서 만들고Go로 작성되었다.
테라폼 바이너리가 나를 대신해 provider(aws, gcd, azure등)에 API 콜을 보내기 때문에 나는 추가적으로 provider API 호출 할 필요 없다.
테라폼 바이너리 파일이 provider api를 호출하고  테라폼에서 인프라 설정파일 쪼개서 프로비저닝한다.

## 5. 테라폼이랑 다른 IaC툴 비교해보기

저자가 다른 툴 냅두고 왜 테라폼 결정하게 되었는지 이야기해줌

- 설정관리(Ansible) VS 프로비저닝(Terraform)
- mutable infrstrcture VS immutable infrastructur
- 절차형 언어(Ansible) VS 선언형 언어(Terraform)
- master VS masterless
- agent vs agentless
- 여러개 IaC툴 짬뽕해서 쓰기

### 5-1. 설정관리(Ansible) VS  프로비저닝(Terraform)

- `Chef`, `Puppet`, `Ansible`, `SaltStack` = configuration management tools
- `Cloudformation`, `Terraform`, `OpenStack Heat` = provisiong tools

둘의 차이는 확실하게 말하긴 힘들지만 configuration management tools은 보통 어느 정도의 프로비저닝을 할 수 있고(앤서블로 배포가능)
provisiong tools또한 어느정도의 configuration 할 수 있다 (테라폼으로 configuration scripts)

내 유즈케이스에 맞게 괜찮은 툴을 사용할 것 

- docker, packer : server templating tools
도커파일이나 패커 템플릿으로 이미 이미지를 만들었다면 provision the infrastructe for running image가 필요하다. 그리고 프로비저닝을 할 때면 프로비저닝을 쓸게 필요할것임
- 만약에 서버 템플레이팅 툴을 사용하지 않는다면 configuration mange + provisiong tool 같이 쓰는게 좋다
- 테라폼을 서버 프로비저닝에 사용하고 chef로 각각의 서버를 configure하는데 사용하는것등→chef로 configure한 것을 테라폼으로 프로비저닝

그런데 이미지 사용할꺼니까 결국에는 configure + provisiong + templating tool 같이 적절하게 짬뽕해서 써보자.

### 5-2. mutable infrstrcture VS immutable infrastructure

- `Ansible`  `Chef`, `Puppet`, '`SaltStack` 디폴트로 mutable infrastructure paradigm 만약에 `Chef` 로 OpenSSl 새 버전 설치 지시한다면 존재하는 모든 서버에 sw 업데이트 일어날거고 추가 업데이트 할 때마다 모든 서버는 유니크한 변경사항이 생김 -> 결론적으로 모든 서버는 조금씩 달라질것임. 이런경우는 자동화된 테스트로도 알아채기힘듬(서버를 매뉴얼적으로 관리한다면 생길 수 있는 프로그램임 그저 configuration tool을 사용한다면 덜 문제가 될뿐) a configuration management 변경사항은 테스트 서버에서는 괜찮아 보이겠지만 프로덕션 서버에서는 변경사항이 생길 수 있음 왜냐면 production server가 오랜시간 쌓아온 변경사항이 테스트 서버 환경과 같지 않을 것이기 때문
- 하지만 Docker나 Packer로 만들어진 이미지를 테라폼과 같은 provisiong tool 사용한다면 변경사항 쉽게 캐치가능. 만약에 새 버전의 OpenSSL을 갖는 서버를 배포하고 싶다면 Packer를 이용해 새 버전의 OpenSSL을 갖는 이미지를 만들고, 그 이미지를 deploy across a set of new servers 그리고 old 버전의 서버를 종료한다. 왜냐면 모든 새 배포는 fresh server에 immutable image를 사용하기 때문. 이러한 것들은 configutraiton drfit bugs를 줄일 수 있고 어떤 소프트웨어가 어떤 서버에서 실행중인지 파악가능함. 또 어떠한 버전의 어떠한 소프트웨어(그전버전의 이미지)를 쉽게 배포할 수 있도록함. 또 자동화 테스트를 테스트서버에서도 쉽게할수있고 프로덕션 환경과 똑같이!  → 단점도 있음. server template 통해 이미지 다시 만들고 다시 모든 서버에 배포한다면 (아주 작은 변경사항을 가진), 시간이 좀 오래걸릴것임 그리고 immuability는 실제로 image를 run 했을 때까지만 유효함. 서버가 시작되고 동작한다면  (뭔말임?)
- 물론 configutraiton maangement tool도 immutale 배포 가능하긴한데 관용적인 방법은 아님

### 5-3. 절차형언어(Ansible) vs 선언형언어(Terraform)

- 질문1 : 10개의 인스턴스를 이미 프로비저닝을 했다고 하자.만약에 트래픽이 증가해서 추가적 5개의 인스턴스(토탈15개)를 만들어야한다면?
    
    Ansible은 관리설정툴이기 때문에 현재 인프라 상태를 알 수가 없다. 따라서 기존에 10개의 인스턴스를 5로 수정해야한다.
    
    반면 Terraform은 실행 할 때마다 provider API를 호출해 인프라의 상태를 확인하므로 희망하는 인스턴스개수 총 15개로 작성하면된다.
    
    ```bash
    # ansible 코드 
    - ec2:
    	count: 10 -> 5개로 수정해야하함
    	image : ami-0c55b159cbfafe1f0
    	instance-type: t2.micro
    
    ```
    
    ```yaml
    # Terraform 코드 
    resource "aws_instance" "example" {
    	count = 10 -> 15개
    	ami = "ami-0c55b159cbfafe1f0"
    	instance_type = "t2.micro"
    }
    ```
    
- 질문2  만약에 다른 버전의 앱을 배포하고싶다면? ami바꿔서?
    
    `ansible`같은 절차지향형에서는 별로 도움이 안됨. 기존에 15개의 인스턴스를 내리고 새 버전을 다시 배포해야함 `테라폼` 에서는 기존 코드에서 ami만 바꿔주면됨
    
    ```go
    resource "aws_instance" "example" {
    	count = 15
    	ami = "ami-02bccb11111111b802"
    	instance_type = "t2.micro"
    }
    ```
    
- 결론 :  Ansible같은 절차형은 뭐가 이미 배포됐는지 트랙킹이 안되고 작성된 코드를 재사용하기 힘들다. 반면 Terrform을 사용하면 항상 최신 상태 유지 가능하고 코드 재사용가능(물론 테라폼도 제한적인게 있겠다만)

### 5-4. master vs masterless

`Chef` , `Puppet` , `SaltStack`  같은 설정관리툴은 분산된 인프라 상태를 확인하기 위해 마스터 서버가 필요함(masterless모드가 존재하기는하다만) 따라서 인프라를 업데이트 할 때 마다 마스터서버에 연결하고 나서 모든 서버를 업데이트 해야한다.

- 장점
    - 서버를 모두 관리할 수 있는 중앙 서버가 있기에 전체 인프라를 한눈에 파악할 수 있다
    - 마스터가 아닌 다른 서버를 revert change
- 단점
    - 추가적인 마스터 서버 배포 과정 필요. 근데 고가용성을 위해 추가적인 마스터 서버의 슬레이브들이 필요함
    - 마스터서버를 관리해줘야함 scale + back up + monitor + maintian + upgrade
    - 마스터서버 통신을 위해 포트 열어줘야해서 보안에 취약할 수도 있음

반면 `Ansible` , `Cloudformation`, `Heat` , `Terraform` 은 디폴트로 masterless. 정확히는 이들중은의 몇개는 마스터 서버에 의존적이겠지만 이미 infra 파트여서 사용자가 추가적인 관리가 필요없음. `Terraform` 은 cloud privder와 커뮤니케이션 할 떄 cloud provider의 api를 사용하고 이러한 api server 는 마스터 서버다 하지만 추가적인 인증절차나 추가 인프라가 필요하지 않음. 

### 5-5. agent vs agentless

`Chef` , `Puppet` , `SaltStack`  → 추가적인 agent SW 필요(Chef client, puppet agent, salt minion등) 각 각의 서버 configure를 하기 위해 설치 필요.

이러한 agent은 보통 각 서버의 백그라운드에서 실행되고 가장 최신 관리 상태를 업데이트를 유지하기 위해설정관리를 설치하는 책임을 갖고 있음. 

(물론 `Chef` , `Puppet` , `SaltStack`은 다양한 버전의 agentless modes를 제공한다만)

그렇다면 태초에 서버를 어떻게 프로비전하고  그안에 agent SW를 설치할 수 있을까?  → 또 다른 설정관리 툴을 사용한다면 괜찮음(테라폼으로 agent SW가 이미 설치되어있는 AMI를 배포한다든가 등)

단점

- 유지보수 :  agent SW 업데이트시 조심해야함 마스터 서버가 있다면 이와 싱크가 맞아야 하기 때문 또 agent SW가 crash하면 재실행될 수 있게 모니터링도 필요
- 보안 : 만약에 agent SW가 마스터서버로 부터 configuration 을 pulls down  을했다면 (혹은 마스터 서버를 쓰지 않는다면 다른 서버) 아웃바운드 포트를 모든 서버에서 열어줘야함. 만약에 마스터 서버가 configuration을 agent에게 푸쉬했다면 모든 서버에 in-bound 포트를 열어줘야함. 두개의 케이스 모두 어떻게 agent서버가 마스터 서버를 인증할지 고민해봐야함

### 5-5. 여러개 IaC짬뽕해서 써보기

- 프로비저닝 + 설정관리
    - e.g) `Terraform`. + `Ansible`  →Both of them are client only application + many ways to work together (e.g. `Terraform`은 서버 배포시 스페셜 태그 붙는데 `Ansible`이 이러한 태그 이용해서 서버를 찾고 configure하는데 사용) ⚠️ `Ansible`→  절차형코드, mutable server which means your codebase, infra maintenace can be more difficult
    - `Terraform` → underlying infra including N/W (e.g. DB, VPC, load balancer, setvers)
    - `Ansible` → to deploy mu apps on top of those servers
    
- 프로비저닝 +서버 템플레이팅(도커,패커등)
    - e.g) `Terraform`+ `Packer` → `Packer` to package app as VM img
    장점 : no exrtra infra(client only app `Packer` `Terraform`),  immutable infra → goot to maintance
    단점 : VMs takes long time to build and deploy(= slow iteration speed), deployment strategies of Terraform are limited(= Terraform cant implement blue-green deployment natively)→ lots of complicated deployment Or use orchestration tools like (provisiong + server templating + orchestration)
        - `Packer` → package your app as VM image
        - `Terraform` →  a) deploy servers with these VM image  b) the rest of infra(vpc, subnet, rout tables db, loadbalancers)
- 프로비저닝 + 서버템플레이팅 + 오케스트레이션
    - e.g) `Terraform` + `Packer` + `Docker` + `k8s` 
    장점 : docker img built quickly + you can run anad test on your loal + k8s feature(auto healing, auto scaling, , dvarious deployment strategies)
    단점 :  complexity. extra infra to run(`k8s`  is expensibe to run and difficulty) extra layers of abstraction to learn and maange and debug(`k8s` `Packer` `Docker`)
    - `packer` → create vm img that has `Docker` and `k8s`
    - `terraform` → a) deploy a cluster of servers each of which runs this VM image(`Docker`, `k8s`) b) the rest of infra(vpc, subnet, rout tables db, loadbalancers)
    
    ## 6. 추가
    
    ### 6-1. 책 안에서 읽을 목록 추천해주는데 확인해보기
    
    - devops관련 저자 추천책 [https://www.amazon.com/DevOps-Handbook-World-Class-Reliability-Organizations/dp/1942788002](https://www.amazon.com/DevOps-Handbook-World-Class-Reliability-Organizations/dp/1942788002)
    
    ### 6-2. 잘 이해안가는용어
    
    - ad hoc script
    - snowflake server
    - core value of DevOps : CAMS(culture, automation, measurement, sharing)
    - ad hoc scipt
    - idempotence : code that works correctly no matter how many times you run it is called idempotent code 멱등법칙. 연산을여러번하더라고 결과가 달라지징낳는성질
    - blue-green deployment 블루그린배포 : 서버 두개 띄운다음에 트래픽 옮겨가는듯 → 서비스 올드버전, 새버전있으면 올드버전 트래픽유저들을 조금씩 새버전으로 이동시키는 배포형식. 새버전과 구버전 서비스들 동시에 켜놓고 트래픽을 천천ㄴ히 새버전으로 옮기는 방식
    - canary deployment 캐너리배포 : 광산 유독가스 나오면 캐너리가 예민해서 먼저죽기때문에 죽으면 도망간다고함. 왜냐면 서버배포하다가 서버 10개있으면 하나씩 롤링업데이트하는데 하나를 버전2 업데이트했는데 여기에서 에러 많이 발생한다면→ 릴리즈하는걸 스테이징. 블루그린이랑 비슷한데. 작은 유저들을 테스트해보는형식
    - rolling deploymnet 롤링배포
    - auto healing
    - bus factor
    - outage가 무슨뜻이지?
    - bootstrapping이란?
    - 절차형 코드  vs  선언형 코드 차이
        - 절차형코드는 변경사항을 저장해야함 코드 추적필요
        - 선언형코드는 desired status히스토리 신경안써도되지만
    - bootstrapping이란?
    - vm과 컨테이너차이
    
    ### 6-3. 질문들
    
    - 쿠버네티스 는 → 롤링 or 블루그린배포로 사용하는듯
    - 마스터서버를 사용해서 포트를 열어준다면 이게 보안의 리스크가 얼마나갈까?(보안에 취햑하다는것 외에는 책에 많이 안나오기두하구.) → 마스터가 뚤리면 다른 팟도 뚤리기때문에 마스터 없는게 낫다. -?→ 테라폼에서는 마스터가없기때문에 그런부분은 걱정하지 않아도 된다! 앤서블은 포트 22를 열어줘야햐는데 키관리를 따로해줘야함 키관리를 해줘야하기때문에 보안리소스 소모
    - 블루그린, 카나리, 롤링배포 차이