variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EKS node group instances"
  type        = string
  default     = "thinkpad-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "aniket-eks-cluster"
}
