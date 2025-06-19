variable "nodes" {
  description = "Configuration for K3D nodes"
  type = map(object({
    role     = string
    replicas = number
    memory   = optional(string)
  }))
  default = {
    "node-1" = {
      role     = "agent"
      replicas = 1
      memory   = "1g"
    }
    "node-2" = {
      role     = "agent"
      replicas = 1
      memory   = "2g"
    }
  }
}