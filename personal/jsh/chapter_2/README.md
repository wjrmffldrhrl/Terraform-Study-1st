# Setting up your AWS account  

root user를 그대로 사용하는 것은 좋지 않다.
- IAM에서 유저를 생성해서 사용할 것
    - AdministratorAccess 권한 추가

> 해당 책의 예시들은 모두 Default VPC 내부에서 진행된다.  
> AWS의 모든 리소스는 VPC 내부에 배포되고 특정 VPC를 명시하지 않으면 Default VPC에 배포된다.


# Installing Terraform
OS의 package manager를 사용하는게 가장 쉽다.  

mac에서는 Homebrew  
```
$ brew tap hashicorp/tap
$ brew install hashicorp/tap/terraform
```

OR  

[Terraform home page](https://www.terraform.io/)  

Terraform을 생성한 AWS 계정으로 사용 가능하게 하려면 AWS credential을 환경변수로 export 해야 한다.  

```
$ export AWS_ACCESS_KEY_ID=(your access key id)
$ export AWS_SECRET_ACCESS_KEY=(your secret access key)
```  

또는 `$HOME/.aws/credentials` 경로에 crednetial file을 생성해도 된다.  
- `aws configure` 명령어로 생성 가능  


# Deploying a single server
# Deploying a single web server 
# Deploying a configurable web server 
# Deploying a cluster of web servers 
# Deploying a load balancer
# Cleaning up



# Words
- perspective: 관점, 원근법
