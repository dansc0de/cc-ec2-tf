variable "region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "ubuntu 24.04 lts ami"
  type        = string
  default     = "ami-025d99823a4caad37"
}
