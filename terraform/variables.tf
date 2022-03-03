variable "linode_pat" {
  description = "Personal access token to access linode API"
  type        = string
  sensitive   = true
}

variable "root_pass" {
  description = "Root password for linodes"
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "Private key for linodes"
  type        = string
  //sensitive   = true
}

variable "k8s_version" {
  description = "The Kubernetes version to use for this cluster. (required)"
  default     = "1.21"
}

variable "label" {
  description = "The unique label to assign to this cluster. (required)"
  default     = "default-lke-cluster"
}

variable "region" {
  description = "The region where your cluster will be located. (required)"
  default     = "eu-central"
}

variable "tags" {
  description = "Tags to apply to your cluster for organizational purposes. (optional)"
  type        = list(string)
  default     = []
}

variable "pools" {
  description = "The Node Pool specifications for the Kubernetes cluster. (required)"
  type = list(object({
    type  = string
    count = number
  }))
  default = [
    {
      type  = "g6-standard-4"
      count = 3
    },
    {
      type  = "g6-standard-8"
      count = 3
    }
  ]
}