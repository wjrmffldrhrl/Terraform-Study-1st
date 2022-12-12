1. 레퍼런스: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance.html
2. 주요 명령어

```
terraform init
terraform plan
terraform apply
terraform graph
terraform destroy
```

3. 네트워크 보안 (vpc)
  - public은 테스트에는 적합하나 실제 환경에는 적합하지 않음.
  - 실제 환경에서는 private을 사용하고 프록시 서버나 로드 밸런서만 public으로 설정해야 함

4. 로드밸런서
  - ALB: HTTP(S)에 트래픽 처리에 적합한 로드 밸런서 OSI 7계층에서 동작
  - NLB: TCP, UDP, TLS 트래픽 처리에 적합하고 ALB보다 빠르게 확장/축소 가능, 초당 수천만의 요청을 처리할 수 있도록 처리 (OSI 4계층)
  - CLB: 레거시 로드 밸런서로 4계층, 7계층 모두 작동하나 기능은 훨씬 적음
  - [비교](https://aws.amazon.com/elasticloadbalancing/features/#Product_comparisons)
