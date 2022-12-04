output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

output "subnet_ids" {
  value       = data.aws_subnet_ids.default.ids
  description = "The IDs of the subnets used by the load balancer"
}
