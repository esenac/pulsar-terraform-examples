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
    "two",
    "three",
    "four",
    "five"
  ]
}

variable "topics" {
  default = {
    "one" = [
      "alpha", 
      "beta", 
      "gamma", 
      "delta", 
      "epsilon", 
      "zeta", 
      "eta", 
      "theta", 
      "iota", 
      "kappa", 
      "lambda", 
      "mu"
    ]
    "two" = [
      "alpha", 
      "beta", 
      "gamma", 
      "delta", 
      "epsilon", 
      "zeta", 
      "eta", 
      "theta", 
      "iota", 
      "kappa", 
      "lambda", 
      "mu"
    ]
    "three" = [
      "alpha", 
      "beta", 
      "gamma", 
      "delta", 
      "epsilon", 
      "zeta", 
      "eta", 
      "theta", 
      "iota", 
      "kappa", 
      "lambda", 
      "mu"
    ]
    "four" = [
      "alpha", 
      "beta", 
      "gamma", 
      "delta", 
      "epsilon", 
      "zeta", 
      "eta", 
      "theta", 
      "iota", 
      "kappa", 
      "lambda", 
      "mu"
    ]
    "five" = [
      "alpha", 
      "beta", 
      "gamma", 
      "delta", 
      "epsilon", 
      "zeta", 
      "eta", 
      "theta", 
      "iota", 
      "kappa", 
      "lambda", 
      "mu"
    ]
  }
}
