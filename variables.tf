variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}

variable "function_name" {
  type = string
}

variable "publish" {
  type    = bool
  default = true
}
