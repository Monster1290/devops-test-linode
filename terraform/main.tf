terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.16.0"
    }
  }
}

# Configure the Linode Provider
provider "linode" {
  token = var.linode_pat
}

resource "linode_lke_cluster" "test_lke" {
  k8s_version = var.k8s_version
  label       = var.label
  region      = var.region
  tags        = var.tags

  dynamic "pool" {
    for_each = var.pools
    content {
      type  = pool.value["type"]
      count = pool.value["count"]
    }
  }
}

resource "linode_sshkey" "macbook" {
  label   = "macbook"
  ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC56dRKHr9KX6FCDoSWMaG8HjnwovMqv61uyKu6TBC3REVewm2rwB901Lzjk/W9MKkXgwBbQ1cZ8zarX2epadveRpqvHFQgGvxQRr+6IMoQu7KjWuB3Oi4H1RYNjxH91E5MaCckqnzEAHCFHL9yMknyMZ6H8p+9XUdg3i7c13QY8uNlQXGpahTi6NtDrIloIxzPJ46OR2N5KvNQpeDv0TjlG/dRexvbsjYrphE5CpT9mqHnI+CaZey27IEb39jSl85Wi+tWpSV6dWPmelpemt2G+/Xv1fAXmDsblttgI1JUae0vl+H4YB7qMGRvBqNQ99nM/YQgb4rTxzedIleCJlFyoDyKMgi9ihlCIuNA8mvAIxktU5eTASwUbRH6f7kmPNlstN1fjJodhWUi4KEbdh2luVmmVquiOW1CpqwKus3QZbLx2e8TG7sfAuck6TVn8XcnY1xgnIYTajiZHITSVWikBuDrovp+temg5JsbAmqZT5zm8doUcfcDgC4/bKa63P8= besedin@MacBook-Air-Aleksandr.local"
}

resource "linode_instance" "cicd-server" {
  image           = "linode/ubuntu20.04"
  label           = "CICD-server"
  region          = var.region
  type            = "g6-standard-1"
  authorized_keys = [linode_sshkey.macbook.ssh_key]
  root_pass       = var.root_pass
  private_ip      = true
}

resource "linode_instance" "test-server" {
  count           = 2
  image           = "linode/ubuntu20.04"
  label           = "test-server"
  region          = var.region
  type            = "g6-standard-1"
  authorized_keys = [linode_sshkey.macbook.ssh_key]
  root_pass       = var.root_pass
  private_ip      = true
}

resource "linode_instance" "staging-server" {
  count           = 1
  image           = "linode/ubuntu20.04"
  label           = "staging-server-${count.index + 1}"
  region          = var.region
  type            = "g6-standard-1"
  authorized_keys = [linode_sshkey.macbook.ssh_key]
  root_pass       = var.root_pass
  private_ip      = true

  provisioner "local-exec" {
    command = "ansible-playbook -u root -T 60 -i '${self.ip_address},' --private-key ${var.ssh_private_key} ../ansible/jenkins_agent_node.yml"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      ANSIBLE_CONFIG = "../ansible/ansible.cfg"
    }
  }
}

//Export this cluster's attributes
output "kubeconfig" {
  value     = linode_lke_cluster.test_lke.kubeconfig
  sensitive = true
}

output "api_endpoints" {
  value = linode_lke_cluster.test_lke.api_endpoints
}

output "status" {
  value = linode_lke_cluster.test_lke.status
}

output "id" {
  value = linode_lke_cluster.test_lke.id
}

output "pool" {
  value = linode_lke_cluster.test_lke.pool
}