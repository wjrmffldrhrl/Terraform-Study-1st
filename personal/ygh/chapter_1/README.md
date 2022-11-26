# Chapter1: 테라폼을 사용해야하는 이유

## What Is DevOps?: DevOps란
---
 1. 과거 Dev(Developers, 개발팀, 하드웨어 구축 담당)팀과 Ops(Operations, 운영팀, 배포 및 운영 담당)팀이 나눠져있던 시절의 문제점으로 인한 One-team화
    
    `Snowflake servers`: 회사 규모 확대 → 서버 증가 → 개발 서버에서는 잘 작동했으나 배포시 문제 발생하는 경우가 더 많이 발생 → 문제가 되는 서버만 임의로 수정 → 각 서버마다 다른 configuration을 가지게 되는 경우가 많아짐
 
 ➢ Dev팀과 Ops팀의 사일로화로 인한 문제점 발견으로 인해 DevOps 탄생


 2. 클라우드의 발전으로 인프라 구축/유지에 소요되는 리소스가 줄어듦에 따라, Dev팀과 Ops팀 모두 물리적인 곳 보다 sysadmin 코드 작성에 더 많은 시간을 쏟게 되면서 두 팀간의 경계가 희미해짐

```text
 DevOps의 네 가지 기조는 문화, 자동화, 측정, 공유 (CAMS - Culture, Automation, Measurement, Sharing)
 ```

</br>

## What Is Infrastructure as Code?: IaC란?
---

 <center><h3 style="color:gray"> "인프라를 코드로 정의, 배포, 업데이트, 제거하는 것" </h3></center>

</br>

### IaC 방법 1. Adhoc Script
 
 목적에 따라 script를 작성하는 것. 즉, 작성자가 임의로 개발 언어를 사용해 인프라를 구축하는 것

* 특징:
    1. 일반적으로 많이 사용하는 프로그래밍 언어 사용 가능
    2. 원하는대로 코드를 작성할 수 있음

위와 같은 특징 때문에 명확한 장단점을 가짐.
* 장점 : 작성하기 편하고 목적에 맞게 사용할 수 있음
* 단점 : 코드가 복잡해지기 쉬움

### IaC 방법 2. Configuration Management Tools: 형상관리툴

 이미 존재하는 서버에 소프트웨어를 설치하고 관리해주는 툴

 Chef, Puppet, Ansible이 여기에 속함

 * 장점:
    1. `컨벤션`: 구조화되어있기 일관성있고 예측가능함, 파라미터를 사용하기 때문에 직관적임, 시크릿 사용
    2. `멱등성`: 같은 코드를 여러 번 실행해도 현재 상태에 맞춰서 script를 실행함. 예를 들어, 특정 패키지를 설치하라는 명령어를 내릴 경우, adhoc script는 개발자가 패키지의 설치 여부를 기억하고 명령어를 내릴 지 말지 상황에 따라 다르게 수행하거나 script 내에 if문을 별도로 작성해야하지만, Ansible의 경우 알아서 설치되어 있는 경우와 설치되어있지 않은 경우를 구분함
    3. `동시 배포`: Adhoc script는 해당 스크립트가 존재하는 서버에 종속적이지만 형상관리툴들은 여러 대의 서버에 동시에-병렬로 배포하거나, 여러 대의 서버에 대한 설정을 하나의 스크립트에 작성할 수 있음

### IaC 방법 3. Server Templating Tools

> `Packer`,`Vagrant`와 같은 server templating 툴들은 docker 엔진이 설치되어 있는 AMI를 생성하거나 docker image를 작성할 수 있는 툴이다.

 * 서버의 이미지: OS의 특정 상태를 기록(snapshot)해 놓은 것

 Server Templating Tool의 핵심은 **인프라의 항상성 유지** - 한번 정의된 서버는 그 정의를 바꾸지 않고 항상 동일한 상태를 유지하도록 하며, 바꾸어야하는 경우 새로운 버전의 템플릿을 작성하는 방향을 제시

 * 이미지 관련 툴 - **가상머신과 컨테이너**
  둘의 차이는 추상화 정도.
VM은 Host OS단 ~ 하드웨어 단으로 서버의 OS 커널과 하드웨어가지도 격리하지만 컨테이너는 Kernal space가 아닌 User space 위에 컨테이너 엔진을 띄우기 때문에 각 Guest OS 간 커널과 하드웨어는 공유 (별도 virtualization.md 파일 참고)

### IaC 방법 4. Orchestration Tools
 
 Server Templating Tool들을 관리하는 다음과 같은 역할을 함

 1. VM, 컨테이너 배포
 2. 배포 전략을 사용하여 기존 VM, 컨테이너 플릿에 대한 업데이트 롤아웃
 3. Auto healing
 4. Auto scaling
 5. Load balacing
 6. Service discovery

 * 종류: Kubernetes, Marathon/Mesos, ECS, Docker Swarm, Nomad

 Sever Templating Tool 중 하나인 Docker image를 관리해주는 툴인 Kubernetes의 마스터노드를 관리해주는 서비스로 각 3 클라우드 벤더사에 EKS, GKE, AKS가 있음

 <font color="gray" size="x-small"> (관리를 위한 관리를 위한 관리랄까.. 관리자라고 해서 관리가 필요하지 않은 것은 아니다. 마치 CICD 파이프라인이 생겼다고 QA가 짤리지 않듯..) </font>

### IaC 방법 5. Provisioning Tools

 Terraform, CloudFormation, OpenStack Heat, Pulumi 와 같이 서버를 생성하는 툴. 여기서 이야기하는 "서버"는 한 프로젝트에 필요한 서버 그 자체 뿐 아니라 데이터베이스, 캐시, 로드 밸런서, 큐, 모니터링 시스템, 서브넷, 방화벽, 라우팅 등 인프라를 모두 포함

 Provisioning Tool 코드 하나면 해당 툴이 지원하는 모든 플랫폼에서 동일한 구성의 인프라를 _무한대_ 로 찍어낼 수 있음

</br>

```
IaC의 장점
 1. DevOps의 과정을 코드화: 수동 작업으로 생기는 오류 제거, 자동화되는 작업들이 생기면서 작업 리소스를 효율적으로 분배할 수 있게 됨
 2. 안전성, 신뢰성 확보
 3. 변경사항의 history가 보관되어 있음: 재현가능성 증가, 재사용(=복제)-수정-버저닝 가능
 4. 작업 내용이 기록 상태로 남아있음
```

## IaC 툴을 선정할 때 고려해야할 부분들
---

 많은 IaC툴들이 중복된 기능들을 제공하기 때문에 선택에 있어 다음과 같은 기준들을 제시

### 형상관리 vs 프로비저닝

 서버 템플릿 툴을 사용한다면 대부분 형상관리 기능을 제공하기 때문에 프로비저닝 툴을 추가로 사용하는 것이 좋고(Terraform(provisioning) + Docker(Server Template Tools)), 반대로 서버 템플릿 툴을 사용하고 있지 않다면 형상관리와 프로비저닝 툴을 함께 사용하는 것이 좋은 대안이 될 수 있음 (Terraform (provisioning) + Ansible (configuration management))

</br>

### 변경 가능성이 있는 인프라 vs 변경 가능성이 없는 인프라 (?)

 * 대부분의 형식적인 configuration management tools은 Mutable infrastructure 파라다임
    ➢ 이미 존재하는 서버에 변경을 가하는 작업을 수행하기 때문에 기존에 구성되어있는 서버의 영향을 받고, 각 서버(개발vs운영)마다 설정이 달라지는 문제 발생 가능성 존재

 * provisioning tool은 배포가 진행될 때마다 새로운 서버에서 새로운 이미지를 생성하기 때문에 Immutable infrastructure 패러다임

  만약 chef를 통해 openssl의 새로운 버전을 설치한다면 이미 존재하는 서버에 소프트웨어 업데이트를 수행
  
  ➢ in place로 실행 → 시간이 흐르면서 업데이트가 계속 발생할수록 각 서버는 저마다의 변경 히스토리를 가짐.
  
  ➢ 결론적으로 각각 조금씩 다른 서버가 될 수 있음.

</br>

### 절차형 언어 vs 선언형 언어

 * 절차형: Checf, Ansible
 * 선언형: Terraform, CloudFormation, Puppet, OpenStack Heat, Pulumi

</br>

**✓ IaC 툴로 절차형 언어를 사용했을 때의 문제점:**

<center> <font size="5pt" color="orange"> "현재의 상황을 반영하지 않음" </font> </center>

 선언형 언어는 지난 코드에서 **변경된 사항**을 반영하지만 절차형 언어의 경우 현재 서버의 상황은 반영하지 않고 실행하는 코드 그 자체를 그대로 실행

 
 예를 들어, 지난 코드를 통해 구축한 클러스터 개수가 5개고, 해당 파라미터를 25로 수정했다고 했을 때,
    - 절차형: 변경사항이 아닌 코드 자체를 반영하므로 25개를 새로 생성해서 총 클러스터 개수는 30개가 되고
    - 선언형: 변경사항을 반영하기 때문에 해당 코드를 돌렸을 때 최종 파라미터 개수가 25개가 되도록 20개만 추가로 생성

 따라서, **"코드의 재사용이 제한적임"**.

 반면, 선언형 언어의 경우 코드의 변경사항을 인식할 수 있기 때문에 작성자는 desired state만 고려하여 코드를 작성하면 됨

</br>

 ### GPL vs DSL

    ✓ GPL (General-Purpose Language) : 일반적으로 사용하는 개발언어들 (Python, Java, Javascript, C#...)

    ✓ DSL (Domain-Specific Language) : Terraform-HCL, Puppet-Puppet Language

 * DSL을 지원하는 툴과 비교했을 때 GPL을 지원하는 IaC툴의 장점:
    1. 복잡한 로직(loops, conditionals,..) 구현 용이
    2. 다른 툴/ API와의 통합 기능을 쉽게 제공
    3. 커뮤니티

 * GPL을 지원하는 툴과 비교했을 때 DSL을 지원하는 IaC툴의 장점:
    1. 특정 목적 하나를 위해 개발된 언어기 때문에 사용되는 변수나 키워드들이 명확
    2. 단일화된 형태로 작성되기 때문에 예측가능한 구조를 취하며, 검색 용이

</br>

 ### 마스터 서버의 유무

  마스터 서버가 있으면 여러 대의 서버를 상태를 트래킹하고 제어할 수 있는 중앙 서버가 있다는 장점이 있지만, 그 서버 한 대를 운용하는 리소스가 추가로 소요되며, 각 노드와의 소통을 위해 extra port를 개방함으로써 보안 issue가 발생할 수 있으므로 상황에 따라 적절하게 선택하는 것이 필요

  * Chef, Puppet: 상황에 따라 선택해서 serverless로 운영가능
  * CloudFormation, Heat, Terraform, Pulumi: Masterless(default) 또는 마스터 서버를 추가 서버가 아닌 인프라의 일부로 설정
  * Ansible: Masterless, 각 서버 간 SSH로 연결

</br>

 ### Agent vs Agentless
 
 Agent 방식의 경우 별도 소프트웨어 설치가 필요하기 때문에 해당 소프트웨어를 어떻게 설치/업데이트할 것인가에 대한 고민과 보안 문제가 단점으로 작용

 Agent 워크스테이션 → Agent 서버 → 앱서버 통신 과정 추가 → 에러 발생 확률 상승

 Agentless의 경우 Cloud provider의 API를 사용하거나(e.g. Terraform) SSH와 같은 이미 서버에서 돌아가고 있는 일반적인 데몬을 사용(e.g. Ansible)하여 인증을 진행

 ### 무료 vs 유료

 무료와 유료 모두 제공: Terraform, Chef, Puppet, Ansible, Pulumi

</br>

 ### 커뮤니티의 크기, 검증된 기술(성숙도) vs 최신 기술

 얼마나 많은 사람들이 사용해 보았는가, 얼마나 빠른 피드백이 오가는가, 얼마나 업데이트가 빨리 이루어지는가, 얼마나 이슈에 빨리 대응할 수 있는가

</br>

 ## 여러 IaC 툴들을 동시에 사용하기
---
 ### Provisiong + Configuration management

 ✓ 예시:
    - 인프라(서버, 네트워크 등) 배포: Terraform
    - 앱 배포: Ansible
 장점: 두 툴 모두 client-only 어플리케이션이기 때문에 추가 인프라 설치 불필요
 단점: Ansible이 절차형 코드기 때문에 절차형 코드의 단점들을 가져감, 배포 전략 제한(Terraform)

</br>

 ### Provisioning + Server templating

 ✓ 예시:
    - 앱을 이미지로 작성: Packer
    - 인프라(서버, 네트워크 등)와 해당 서버 위에 VM 배포: Terraform
 장점: 두 툴 모두 client-only 어플리케이션이기 때문에 추가 인프라 설치 불필요, immutable 인프라들로 구성되어 있기 때문에 항상성 유지 (코드가 변경될 경우 현재 서버를 죽이고 새로운 서버를 생성함)
 단점: VM을 빌드 및 배포하는데 많은 시간 소요, 배포 전략 제한(Terraform)

 ### Provisioning + Server templating + Orchestration

 ✓ 예시:
    - Docker와 Kubernetes 에이전트가 설치된 image 작성: Packer
    - Pakcer로 작성된 이미지와 해당 컨테이너가 실행될 인프라 구축 및 배포: Terraform
    - Terraform으로 배포된 서버 운영 및 도커 컨테이너 관리: Kubernetes

</br>

 ## 일반적으로 많이 쓰는/인식되는 툴 정리

 ||Chef|Puppet|Ansible|Pulumi|CloudFormation|Heat|Terraform|
 |:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
 |`Is_open`|Open|Open|Open|Open|Closed|Open|Open|
 |`클라우드회사`|All|All|All|All|AWS|All|All|
 |`Type`|Config mgmt|Config mgmt|Config mgmt|Provisioning|Provisioning|Provisioning|Provisioning|
 |`Infra`|Mutable|Mutable|Mutable|Immutable|Immutable|Immutable|Immutable|
 |`Paradigm`|절차형|선언형|절차형|선언형|선언형|선언형|선언형|
 |`언어`|GPL|DSL|DSL|GPL|DSL|DSL|DSL|
 |`Master`|Y|Y|N|N|N|N|N|
 |`Agent`|Y|Y|N|N|N|N|N|
 |`Paid Service`|Optional|Optional|Optional|필수|해당없음|해당없음|Optional|
 |`커뮤니티`|큼|큼|거대함|작음|작음|작음|거대함|
 |`성숙도`|상|상|중|하|중|하|중|

</br>

```
✔︎ Terraform 작동 방식
 
 - HashiCorp에서 개발
 - Go로 작성
 - 오픈소스
 - API call을 통해 클라우드 provider와 소통
 ```