variable "aws_region" {
    type = string
    default = "ap-northeast-3"
}

variable "infra_name" {
    type = string
    defalut = "de-datahub"
}

variable "infra_tags" {
    type = map(string)
    default = {
        Owner = "de"
        Project = "datahub"
    }
}