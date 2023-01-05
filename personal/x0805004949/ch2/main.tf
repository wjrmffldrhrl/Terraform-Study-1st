########################################
##### 1. A Single Server ###############
########################################
# provider "aws" { 
#   region = "us-east-2"
# } 
# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"
#   tags  = {
#     Name = "teraform-ch2-example"
#   }
# } 
# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 


########################################
##### 2. A Single Webserver ############
########################################

# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"


#   user_data=<<-EOF
#               #!/bin/bash
#               echo "Hello12345, World" > index.html
#               nohup busybox httpd -f -p 8080 &
#               EOF 

#   vpc_security_group_ids = [aws_security_group.instance.id]

# tags = {
#       Name = "teraform-ch2-example"
#   }
# }



# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 



########################################
## 3. A Single Webserver + Configure ###
########################################

# 테라폼 변수 생성
# variable "server_port" {
#   description = "The port the server will use for HTTP requests"
#   type        = number
#   default     = 8080 # 


# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"


#   user_data=<<-EOF
#               #!/bin/bash
#               echo "Hello12345, World" > index.html
#               nohup busybox httpd -f -p ${var.server_port} & 
#               EOF 

#   vpc_security_group_ids = [aws_security_group.instance.id]

# tags = {
#       Name = "teraform-ch2-example"
#   }
# }


# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }


# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 


########################################
## 4.Cluster of Webserver ##############
########################################

# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_launch_configuration" "example" {
#   image_id  = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"
#   security_groups = [aws_security_group.instance.id]


# # 포트번호 변수 사용
# user_data = <<-EOF
#             #!/bin/bash
#             echo "Hello12345, World" > index.html
#             nohup busybox httpd -f -p ${var.server_port} &
#             EOF

# # 만약에 ASG 에서 lanuch configutration 사용하는경우
# lifecycle {
#     create_before_destroy = true
#   }
# }

# data "aws_vpc" "default" {
#   default = true
# }


# # subnet 사용 (다른 데이터 상수사용)
# data "aws_subnet_ids" "default"{
#   vpc_id = data.aws_vpc.default.id

# }

# resource "aws_autoscaling_group" "example" {
# # launch_configuration -> immutable
# # 만약에 내가 launch_configuration에 파라미터조금이라도 수정했다면 
# # 테라폼에서는 기존에 있던 인스턴스를 꺼버리고 새로 생성해야함
# # 근데 ASG가 기존에 있던 리소스를 참조하고있기 때문에
# # 테라폼에서 지울 수 없을 수도 있음 따라서 
# # lifecycle 세팅을줌 ; 기존리소스 삭제하기전에 새로 생성할수있도록
#  launch_configuration = aws_launch_configuration.example.name
#   vpc_zone_identifier = data.aws_subnet_ids.default.ids
  
# min_size=2
# max_size=10
# tag {
#   key = "Name"
#   value = "terraform-asg-example"
#   propagate_at_launch = true
# }
# }


# # 테라폼 문법 변수 생성하기
# # variable "NAME" {설정}
# variable "server_port" {
#   description = "The port the server will use for HTTP requests"
#   type        = number
#   default     = 8080 
# }


# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }



########################################
## 5.Cluster of Webserver + ALB ########
########################################

provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id  = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]


# 포트번호 변수 사용
user_data = <<-EOF
            #!/bin/bash
            echo "Hello12345, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

# 만약에 ASG 에서 lanuch configutration 사용하는경우
lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}


# subnet 사용 (다른 데이터 상수사용)
data "aws_subnet_ids" "default"{
  vpc_id = data.aws_vpc.default.id

}

resource "aws_autoscaling_group" "example" {
# launch_configuration -> immutable
# 만약에 내가 launch_configuration에 파라미터조금이라도 수정했다면 
# 테라폼에서는 기존에 있던 인스턴스를 꺼버리고 새로 생성해야함
# 근데 ASG가 기존에 있던 리소스를 참조하고있기 때문에
# 테라폼에서 지울 수 없을 수도 있음 따라서 
# lifecycle 세팅을줌 ; 기존리소스 삭제하기전에 새로 생성할수있도록
 launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]

    health_check_type = "ELB"

min_size=2
max_size=10
tag {
  key = "Name"
  value = "terraform-asg-example"
  propagate_at_launch = true
}
}


# 테라폼 문법 변수 생성하기
# variable "NAME" {설정}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080 
}


resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# 보안그룹설정된 로드밸런서
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}


# 리스너
resource "aws_lb_listener" "http"{
  load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    # 기본으로 404리턴
  default_action {
  type = "fixed-response"
  fixed_response {
  content_type = "text/plain"
  message_body = "404: page not found"
  status_code = 404
}

}
}


# 보안그룹
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # 인바운드 http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  # 아웃바운드 전체
  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}



# 타겟그룹 및 헬스체그
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
   path = "/"
  protocol = "HTTP"
  matcher = "200"
  interval = 15
  timeout = 3
  healthy_threshold = 2
  unhealthy_threshold = 2
}
}

#  리스너룰  아래 field, values -> depricated
# resource "aws_lb_listener_rule" "asg" {
#   listener_arn = aws_lb_listener.http.arn
#   priority = 100
#   condition {
#     field = "path-pattern"
#     values = ["*"]
# }
#   action {
#   type = "forward"
#   target_group_arn = aws_lb_target_group.asg.arn
# }
# }
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



# 출력
output "alb_dns_name" {
value = aws_lb.example.dns_name
description = "the doname anem of loadbalancer"

}




########################################
##### 1. A Single Server ###############
########################################
# provider "aws" { 
#   region = "us-east-2"
# } 
# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"
#   tags  = {
#     Name = "teraform-ch2-example"
#   }
# } 
# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 


########################################
##### 2. A Single Webserver ############
########################################

# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"


#   user_data=<<-EOF
#               #!/bin/bash
#               echo "Hello12345, World" > index.html
#               nohup busybox httpd -f -p 8080 &
#               EOF 

#   vpc_security_group_ids = [aws_security_group.instance.id]

# tags = {
#       Name = "teraform-ch2-example"
#   }
# }



# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 



########################################
## 3. A Single Webserver + Configure ###
########################################

# 테라폼 변수 생성
# variable "server_port" {
#   description = "The port the server will use for HTTP requests"
#   type        = number
#   default     = 8080 # 


# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"


#   user_data=<<-EOF
#               #!/bin/bash
#               echo "Hello12345, World" > index.html
#               nohup busybox httpd -f -p ${var.server_port} & 
#               EOF 

#   vpc_security_group_ids = [aws_security_group.instance.id]

# tags = {
#       Name = "teraform-ch2-example"
#   }
# }


# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }


# output "instance_id" {
#   value = "${aws_instance.example.id}"
# } 


########################################
## 4.Cluster of Webserver ##############
########################################

# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_launch_configuration" "example" {
#   image_id  = "ami-0fb653ca2d3203ac1"
#   instance_type = "t2.micro"
#   security_groups = [aws_security_group.instance.id]


# # 포트번호 변수 사용
# user_data = <<-EOF
#             #!/bin/bash
#             echo "Hello12345, World" > index.html
#             nohup busybox httpd -f -p ${var.server_port} &
#             EOF

# # 만약에 ASG 에서 lanuch configutration 사용하는경우
# lifecycle {
#     create_before_destroy = true
#   }
# }

# data "aws_vpc" "default" {
#   default = true
# }


# # subnet 사용 (다른 데이터 상수사용)
# data "aws_subnet_ids" "default"{
#   vpc_id = data.aws_vpc.default.id

# }

# resource "aws_autoscaling_group" "example" {
# # launch_configuration -> immutable
# # 만약에 내가 launch_configuration에 파라미터조금이라도 수정했다면 
# # 테라폼에서는 기존에 있던 인스턴스를 꺼버리고 새로 생성해야함
# # 근데 ASG가 기존에 있던 리소스를 참조하고있기 때문에
# # 테라폼에서 지울 수 없을 수도 있음 따라서 
# # lifecycle 세팅을줌 ; 기존리소스 삭제하기전에 새로 생성할수있도록
#  launch_configuration = aws_launch_configuration.example.name
#   vpc_zone_identifier = data.aws_subnet_ids.default.ids
  
# min_size=2
# max_size=10
# tag {
#   key = "Name"
#   value = "terraform-asg-example"
#   propagate_at_launch = true
# }
# }


# # 테라폼 문법 변수 생성하기
# # variable "NAME" {설정}
# variable "server_port" {
#   description = "The port the server will use for HTTP requests"
#   type        = number
#   default     = 8080 
# }


# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }



########################################
## 5.Cluster of Webserver + ALB ########
########################################

provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id  = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]


# 포트번호 변수 사용
user_data = <<-EOF
            #!/bin/bash
            echo "Hello12345, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

# 만약에 ASG 에서 lanuch configutration 사용하는경우
lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}


# subnet 사용 (다른 데이터 상수사용)
data "aws_subnet_ids" "default"{
  vpc_id = data.aws_vpc.default.id

}

resource "aws_autoscaling_group" "example" {
# launch_configuration -> immutable
# 만약에 내가 launch_configuration에 파라미터조금이라도 수정했다면 
# 테라폼에서는 기존에 있던 인스턴스를 꺼버리고 새로 생성해야함
# 근데 ASG가 기존에 있던 리소스를 참조하고있기 때문에
# 테라폼에서 지울 수 없을 수도 있음 따라서 
# lifecycle 세팅을줌 ; 기존리소스 삭제하기전에 새로 생성할수있도록
 launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]

    health_check_type = "ELB"

min_size=2
max_size=10
tag {
  key = "Name"
  value = "terraform-asg-example"
  propagate_at_launch = true
}
}


# 테라폼 문법 변수 생성하기
# variable "NAME" {설정}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080 
}


resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# 보안그룹설정된 로드밸런서
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}


# 리스너
resource "aws_lb_listener" "http"{
  load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    # 기본으로 404리턴
  default_action {
  type = "fixed-response"
  fixed_response {
  content_type = "text/plain"
  message_body = "404: page not found"
  status_code = 404
}

}
}


# 보안그룹
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # 인바운드 http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  # 아웃바운드 전체
  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}



# 타겟그룹 및 헬스체그
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
   path = "/"
  protocol = "HTTP"
  matcher = "200"
  interval = 15
  timeout = 3
  healthy_threshold = 2
  unhealthy_threshold = 2
}
}

#  리스너룰  아래 field, values -> depricated
# resource "aws_lb_listener_rule" "asg" {
#   listener_arn = aws_lb_listener.http.arn
#   priority = 100
#   condition {
#     field = "path-pattern"
#     values = ["*"]
# }
#   action {
#   type = "forward"
#   target_group_arn = aws_lb_target_group.asg.arn
# }
# }
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



# 출력
output "alb_dns_name" {
value = aws_lb.example.dns_name
description = "the doname anem of loadbalancer"

}




