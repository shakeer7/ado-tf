variable "name" {
  type        = string
  description = "name"
}

variable "location" {
  type        = string
  description = "location"
}

variable "tags" {
  type        = map(string)
  description = "tags"
  default     = {}
}
