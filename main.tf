terraform {
  required_providers {
    pulsar = {
      version = "1.0.0"
      source = "registry.terraform.io/apache/pulsar"
    }
  }
}

locals {
    namespaces-map =flatten([ for tenant in toset(var.tenants): [
                                for namespace in toset(var.namespaces): {
                                    tenant = tenant
                                    namespace = namespace
                                }
                              ]
                            ])         

    topics-map = flatten([ for tenant in toset(var.tenants): [
                            for namespace, topic-list in var.topics: [
                                for topic in toset(topic-list): {
                                        tenant = tenant
                                        namespace = namespace
                                        topic = topic
                                    }
                                ]
                            ]   
                        ])
}

provider "pulsar" {
  web_service_url = var.pulsar_service_url
}

resource "pulsar_tenant" "tenants" {
  for_each         = toset(var.tenants)
  tenant           = each.key
  allowed_clusters = ["standalone"]
}

resource "pulsar_namespace" "namespaces" {
  for_each  = {
      for obj in toset(local.namespaces-map): "${obj.tenant}.${obj.namespace}" => obj
  }
  tenant    = each.value.tenant
  namespace = each.value.namespace 
  depends_on = [
    pulsar_tenant.tenants
  ]
}

resource "pulsar_topic" "topics" {
  for_each   = {
      for obj in toset(local.topics-map): "${obj.tenant}.${obj.namespace}.${obj.topic}" => obj
  }
  tenant     = each.value.tenant
  namespace  = each.value.namespace
  topic_type = "persistent"
  topic_name = each.value.topic
  partitions = 1

  retention_policies {
    retention_time_minutes = 1600
    retention_size_mb = 20000
  }

  depends_on = [
    pulsar_namespace.namespaces
  ]
}
