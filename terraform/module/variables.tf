variable "availability_zone_names" {
  type    = list(string)
  default = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1e","us-east-1f"]

}


variable "cidr"{
default="10.0.0.0/16"
}

variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "provider_rigeon" {
 type        = string
 default     = "us-east-1"
}

variable "provider_profile" {
 type        = string
 default     = "dev"
}

variable "dev-ami" {
 type        = string
}