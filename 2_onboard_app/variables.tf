variable "app_id" {}
variable "app_name" {}
variable "bu" {}
variable "lob" {}
variable "environments" {
  default = "dev,prod"
  // ["dev", "prod"]
}

variable "policies" {
  default = {
    "ro" = ["read", "list"]
    "rw" = ["create", "read", "update", "delete", "list"]
  }
}