# 가상화와 컨테이너

## `가상화`
---
### Hypervisior 가상화 (Type 1)

<center><img src="https://imgur.com/fpTCzXm.png" width="400"></center>

 하드웨어 리소스를 Host OS에 할당하지 않고 Guest OS에 직접 할당하는 방법. 하드웨어 i/o 접근을 어디까지 가상화하느냐로 전가상화, 반가상화로 나뉘고, 전가상화에서 속도를 개선한 하드웨어 가상화가 추가되었다.

</br>

**1.전가상화(Full virtualization)**

 하드웨어를 완전히 가상화하는 방법
 
 - 장점: 하드웨어 관리 머신인 VDOM0이 실행되기 때문에 Guest OS의 수정이 필요하지 않다.
    
    복수의 가상 머신이 서로 간섭하지 않기 때문에 처리 오버헤드 낮음
 - 단점: 모든 Guest OS가 하나의 VDOM0을 통해 Hypervisor와 소통하기 때문에 속도 느림. 각 Guest OS의 커널에서는 사용하는 규칙이 모두 다르기때문에 VDOM0에서 번역이 필요

</br>

**2.반가상화(Paravirtualization)**
 
 전가상화의 가장 큰 문제점인 성능 문제를 해결하기 위해 Guest OS 커널을 일부 수정하여 특권 명령이 수행될 때 Hypercall을 호출, Hypervisor가 실행되도록 하는 기술

 가상화 환경에서는 커널 대신 Hypervisor가 하드웨어를 관리하고 보호
    - Hypervisor가 x86에서 제공하는 보호 링 중 가장 권한이 높은 링0에서 실행 커널을 일부 수정
    - 링0에서 실행되는 명령을 보다 낮은 권한인 링1에서 실행
    - 가상 환경과 실제 환경과의 클럭 동기화 같은 일부 명령의 경우 Hypervisor에게 요청하는 Hypercall이 발생하도록 수정

 - 장점: 각 Guest OS가 직접 Hypervisor와 소통하기 때문에 전가상화에 비해서는 속도가 빨라짐
 - 단점: Guest OS 커널 수정이 필요하기 때문에 오픈소스 OS가 아니면 반가상화를 사용하기 어려움

</br>

**3.하드웨어 (지원) 가상화(Hardware virtualization/Hardware Assisted)**

 CPU를 가상화하여 전가상화의 장점과 반가상화의 장점을 모두 취한 방법

 - 장점: 전가상화에서 성능 하락을 일으켰던 Binary Translation을 Hypervisor가 아닌 CPU에서 대신 처리하게 됨으로써 성능, 속도 향상, 커널의 역할을 Hypervisor가 대신함
 - 단점: 특정 하드웨어 종속적(Intel사의 VT-x, AMD사의 AMD-V)

</br>

### Host 가상화 (Type 2)
 이 책에서 말하는 virtual machine. Host OS위에 Guest OS를 올리는 형태이다.

 - 장점: 가상화를 위해 Host 또는 Guest OS를 수정하거나 특별한 CPU 하드웨어 지원이 필요하지 않음
 - 단점: VM의 i/o요청이 Host OS를 통해야하므로 속도가 느리고 오버헤드 발생

## `컨테이너`
---
 OS가 아닌 소프트웨어를 가상화하는 기술. 논리적 구분.

 - 장점: 프로세스를 격리시키기 때문에 가상머신보다 빠르고 가볍다 (CPU, 메모리 오버헤드 거의 없음).
 - 단점: 컨테이너끼리 커널과 하드웨어를 공유하기 때문에 가상 머신 보다 고립화 레벨이 낮음. 즉, 보안이 약함
