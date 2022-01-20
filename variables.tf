variable "pulsar_service_url" {
  type = string
  default = "http://localhost:38080"
}

variable "tenants" {
  default = [
    "foo",
    "bar",
  ]
}

variable "namespaces" {
  default = [
    "one",
  ]
}

variable "topics" {
  default = {
    "one" = [
      "alpha", 
    ]
  }
}
