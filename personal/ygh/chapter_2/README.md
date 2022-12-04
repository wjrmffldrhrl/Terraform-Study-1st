# Chapter2: 테라폼 시작하기

❗️ 테라폼 코드를 Github에 update시 .gitignore파일에 다음 파일들을 포함시킨다 (용량이 너무 커서 그대로 올리면 올라가지 않는다.)
```text
.terraform
*.tfstate
*.tfstate.backup
```

</br>

 원래 Terraform의 behavior는 original instance를 update한다. 하지만 책에 나와있는 User data와 같이 instance가 booting할 때만 작동하는 플랫폼을 사용할 경우 추가적인 옵션을 사용하여 수정 후 배포시 기존 인스턴스가 삭제되고 새로운 인스턴스가 생성되어 reboot될 수 있도록 코드를 작성해야 한다 (p54 참조)

## AWS Setup, 네트워크 설정

Region > AZ(Availability zone), VPC > Subnet

</br>

### VPC

 독립된 하나의 네트워크 영역. 여러개의 AZ에 걸쳐져 있을 수 있다. 하나 이상의 subnet으로 구성되며, 각 subnet에 IP가 할당 된다.

 Default VPC는 public subnet이다.

</br>

### Subnet

 VPC안에서 쪼개지나, 하나의 AZ안에서만 속한다. Public과 private으로 나눌 수 있으며, private subnet은 NAT Gateway를 통하지 않으면 외부로 접근할 수 없다.

 public subnet은 외부에서 접근이 가능하기 때문에 해당 subnet에 두는 리소스들은 최소화하고, 모두 로드발랜싱이나 reverse proxing하는 것이 좋다.

</br>

### Security group 설정
- ingress: inbound traffic
    
    - protocol -1: 모든 프로토콜

    - self (자기참조): True. 해당 보안 그룹 사용 서비스끼리 트래픽 허용 (Whether the security group itself will be added as a source to this ingress rule.) -> CIDR을 0.0.0.0/0으로 설정해두면 안 해도 똑같은거 아닌가?
    
- egress: outbound traffic
    
    ❗️ AWS 콘솔에서 securty group을 생성하면 All Allowed Outbound Traffic을 자동으로 생성해주지만 terraform에서는 All Allowed Outbound Traffic를 default로 설정해주지 않는다.

- CIDR 표현법: IP/(subnet bit 수) : [관련 정리](https://hyunie-y.tistory.com/72)

</br>

### EKS 배포시 네트워크 아키텍쳐

<img src="https://imgur.com/4orItZk.png" width=300px />

</br>

### IAM 권한 설정

 책에서는 Administartor권한을 줬지만 필요한 권한만 세부적으로 주는 것이 엔지니어링 관점에서 적합하다고 생각함.

 EKS 구축 및 운영 위해 IAM 계정에 필요한 권한은 다음과 같다.

- AmazonEC2FullAccess
- AmazonEC2ContainerRegistryFullAccess
- AmazonEKSClusterPolicy
- AmazonEKSServicePolicy
- AmazonS3FullAccess
- AmazonVPCFullAccess
- AmazonRoute53FullAccess
- IAMFullAccess
- AWSCloudFormationFullAccess
- EKS-management (다음 json으로 정의, EKS node group 생성, 조회, 삭제 권한)
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEdiotor0",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:DeleteNodegroup",
                "eks:UpdateNodegroupConfig",
                "eks:ListClusters",
                "eks:CreateCluster"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "arn:aws:eks:*:*:cluster/*"
        }
    ]
}
```

테라폼으로 IAM 권한 설정하는 법 ([공식문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role))

```
resource "aws_iam_role" "<name>" {}
```

</br>

## 테라폼 용어

### providers

 공급자. AWS, Azure와 같이 사용할 플랫폼을 일컫는 용어

### variables

 `variables.tf`를 통해 변수를 관리할 수 있으며 해당 파일에서 선언한 변수는 `var.{변수명}`을 통해 모듈 내에서 사용할 수 있다.

 테라폼의 모든 표현들은 특정 값을 반환한다. 해당 값 역시 output으로 다른 모듈에서 접근해서 사용할 수 있다.

 sensitive라는 파라미터를 통해 secret관리가 가능하다.

### <<-EOF ~~EOF
 테라폼 모듈 내에서 문서형식으로 값을 넣을 수 있게 해준다.
 e.g.
 ```
 resource "aws_instance" "example {
    ami = "ami-***"
    instance_type = "t2.micro"
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello,world" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
    user_data_replace_on_change = true
 }
 ```

</br>

## 테라폼 명령어

</br>

### terraform init

 해당 프로젝트 폴더에 테라폼 초기 설정을 하기 위한 명령어이다. 처음 한번만 수행해주면 된다.

</br>

### terraform apply
 
 코드의 변경사항을 저장한다 (git add와 같은 역할)

</br>

### terraform validate
 
 테라폼 코드에 문제가 없는지 확인한다.

</br>

### terraform plan

 배포 계획을 보여준다.

</br>

### terraform graph
 
 각 작업별 dependency를 볼 수 있다. 최대한 병렬로 수행하지만, 특정 리소스의 아웃풋이 다음 리소스의 인풋으로 들어가는 경우 직렬로 수행한다. DOT이라는 언어를 사용해서 보여주며, GraphvizOnline이라는 웹앱등을 사용해 시각화할 수 있다.

</br>

### terraform apply

 배포를 수행한다. --auto-approve 옵션을 주면 중간에 yes를 넣는 과정을 생략할 수 있다.

</br>

### terraform destory

 만든 리소스를 제거한다.

 작업 중 콘솔로 만든 리소스에 dependency가 걸린 경우 종속성 문제가 발생하여 destory가 중단될 수 있으므로, 테라폼으로 리소스 생성 시 resource를 manually생성하는 것은 최대한 하지 않는 것이 좋다. ([Trouble shooting](https://hyunie-y.tistory.com/69))
