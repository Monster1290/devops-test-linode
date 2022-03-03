label       = "test-lke-cluster"
k8s_version = "1.22"
pools = [
  {
    type : "g6-standard-1"
    count : 3
  }
]

