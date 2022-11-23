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

### Q
- What is outage?


# What is Infrastructure as Code

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