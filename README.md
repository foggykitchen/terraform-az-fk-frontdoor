# terraform-az-fk-frontdoor

This repository contains a reusable **Terraform / OpenTofu module** and progressive examples for Azure Front Door Standard/Premium multi-region HTTP(S) routing and priority-based origin failover.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and follows the catalog's dependency-by-ID composition model. Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is intended as a focused global application-delivery building block for higher-level FoggyKitchen landing-zone and disaster-recovery patterns. It is the Azure L7 anycast counterpart to priority-oriented regional failover patterns; it is not DNS steering and does not implement arbitrary TCP/UDP failover.

## 🎯 Purpose

Create one Azure Front Door profile and endpoint with explicit origin groups, health probes, priority/weight routing, paths, optional externally managed Front Door WAF attachment, and optional diagnostics.

## ✨ What the module does

The module creates:

- One `azurerm_cdn_frontdoor_profile` using `Standard_AzureFrontDoor` or `Premium_AzureFrontDoor`
- One `azurerm_cdn_frontdoor_endpoint`
- One or more origin groups with health probes and load-balancing settings
- Public or Premium Private Link origin references
- Priority-based failover using origin `priority` (`1` is highest; `2` through `5` are standby tiers)
- Routes mapping paths on the endpoint to origin groups
- An optional security-policy attachment to an existing `azurerm_cdn_frontdoor_firewall_policy`
- Optional Azure Monitor diagnostic settings targeting externally managed Log Analytics workspaces
- Tags on the profile and endpoint

The module intentionally does **not** create:

- Resource Groups
- Regional Application Gateways, Load Balancers, VM Scale Sets, compute, App Services, or other origins
- Virtual Networks, subnets, customer-managed Private Endpoints, or Private Link services
- Front Door WAF policy resources
- Application Gateway WAF policies
- Log Analytics workspaces
- Custom domains, certificates, DNS records, rules engines, or databases

Each dependency remains independently owned and is accepted by hostname or resource ID.

## Provider Notes

Live discovery on **2026-10-07** verified AzureRM **4.81.0**, the latest release within this repository's required `< 5.0.0` range at discovery time. The live provider registry also exposed AzureRM 5.x, but FoggyKitchen's static compatibility convention remains `>= 3.100.0, < 5.0.0`. All Front Door resources used here predate the 3.100.0 floor; no higher floor was required. The root module was validated with both 3.100.0 and 4.81.0. Diagnostics deliberately use the older `metric` block because it is accepted by both endpoints of the range; 4.81.0 marks it deprecated in favor of `enabled_metric`, which 3.100.0 does not support.

The exact profile SKU strings are `Standard_AzureFrontDoor` and `Premium_AzureFrontDoor`. Private Link origins require `Premium_AzureFrontDoor`; AzureRM's `private_link` origin block requires `location` and `private_link_target_id`, with optional `request_message` and `target_type`. AzureRM also documents that Private Link requires `certificate_name_check_enabled = true`, which this module validates. Front Door creates a managed private endpoint request that still requires approval on the origin side.

For an Application Gateway custom origin, Azure documentation supports the generated Application Gateway Private Link service resource ID (format includes `Microsoft.Network/privateLinkServices/_e41f87a2_...`), and the Front Door origin Private Link location must match the Application Gateway region. `terraform-az-fk-application-gateway` **v0.2.0** supports `private_link_configuration` and exposes the derived Private Link service ID. Example 02 pins that release and composes a private Application Gateway listener end-to-end. AzureRM 4.81.0 cannot yet configure the newer private-only Application Gateway v2 network-isolation property, so the example includes a compatibility public frontend with no listener; application traffic remains private. Front Door's managed private endpoint request still requires approval on the Application Gateway side after deployment.

Front Door WAF uses `azurerm_cdn_frontdoor_firewall_policy`, not the `azurerm_web_application_firewall_policy` managed by `terraform-az-fk-waf-policy` **v0.1.0**. WAF policy creation is deliberately deferred to a future dedicated module so policy governance stays independent. This module can attach an existing Front Door firewall policy by ID through `azurerm_cdn_frontdoor_security_policy`. Standard supports custom WAF rules; managed rule sets and full WAF capabilities require Premium, so the module does not impose an incorrect blanket Premium requirement for every WAF attachment.

Diagnostics follow the sibling convention: diagnostic settings target the Front Door profile and accept existing Log Analytics workspace IDs. The default category group is `allLogs`, the default metric is `AllMetrics`, and the default Log Analytics destination type is `Dedicated`.

## 📂 Repository Structure

```text
terraform-az-fk-frontdoor/
├── examples/
│   ├── 01_public_priority_failover/
│   ├── 02_premium_private_link_origin/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── SUPPORT.md
├── LICENSE
└── README.md
```

Examples use service- or responsibility-named files instead of a generic `main.tf`. Example 01 separates its Front Door, networking, security, egress, load-balancing, compute, Resource Group, and TLS concerns. Example 02 follows the same shape with `frontdoor.tf`, `application_gateway.tf`, `networks.tf`, `nsg.tf`, `nat_gateway.tf`, `compute.tf`, `resource_group.tf`, and `tls.tf`. Both retain `providers.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`, and `README.md`.

## 🚀 Example Usage

```hcl
module "frontdoor" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-frontdoor.git?ref=v0.1.0"

  name                = "fk-global-web"
  resource_group_name = "fk-global-rg"
  sku_name            = "Standard_AzureFrontDoor"
  endpoint             = { name = "fk-global-web-endpoint" }

  origin_groups = {
    web = {
      health_probe = { path = "/health" }
    }
  }

  origins = {
    primary = {
      origin_group_key   = "web"
      host_name          = "primary.example.com"
      origin_host_header = "primary.example.com"
      priority           = 1
    }
    standby = {
      origin_group_key   = "web"
      host_name          = "standby.example.com"
      origin_host_header = "standby.example.com"
      priority           = 2
    }
  }

  routes = {
    default = {
      origin_group_key  = "web"
      patterns_to_match = ["/*"]
    }
  }
}
```

Origins at the same priority tier are load-balanced by weight. An enabled origin at a higher numeric priority receives traffic only when all enabled origins at lower numeric priorities are unhealthy.

## 📥 Module Inputs

| Variable | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `name` | `string` | yes | — | Azure Front Door profile name. |
| `resource_group_name` | `string` | yes | — | Existing Resource Group containing the profile. |
| `sku_name` | `string` | no | `Standard_AzureFrontDoor` | Standard or Premium Front Door SKU. |
| `response_timeout_seconds` | `number` | no | `120` | Origin response timeout from 16 through 240 seconds. |
| `endpoint` | `object` | yes | — | Single endpoint name and enabled state. |
| `origin_groups` | `map(object)` | yes | — | Origin groups with health probes and load-balancing settings. |
| `origins` | `map(object)` | yes | — | Public host/IP or Private Link origin references, including priority and weight. |
| `routes` | `map(object)` | yes | — | Endpoint path routes to origin groups. |
| `frontdoor_firewall_policy_id` | `string` | no | `null` | Existing Front Door-specific firewall policy ID to attach. |
| `security_policy_name` | `string` | no | `default-security-policy` | Name of the optional security-policy attachment. |
| `diagnostic_settings` | `map(object)` | no | `{}` | Diagnostic settings with external Log Analytics workspace IDs. |
| `tags` | `map(string)` | no | `{}` | Profile and endpoint tags. |

See [inputs.tf](inputs.tf) for complete nested object schemas and validation rules.

## 📤 Module Outputs

| Output | Description |
|---|---|
| `profile_id` | Azure Front Door profile resource ID. |
| `profile_name` | Azure Front Door profile name. |
| `resource_guid` | Profile GUID sent in the `X-Azure-FDID` header. |
| `endpoint_id` | Front Door endpoint resource ID. |
| `endpoint_host_name` | Front Door endpoint host name. |
| `origin_group_ids` | Origin group IDs keyed by logical name. |
| `origin_ids` | Origin IDs keyed by logical name. |
| `route_ids` | Route IDs keyed by logical name. |
| `security_policy_id` | Optional WAF security-policy attachment ID. |
| `diagnostic_setting_ids` | Diagnostic setting IDs keyed by logical name. |

## 🧭 Examples

- `01_public_priority_failover`: deployable Standard Front Door failover lab with two independent regional VNets, private NGINX VMs, NAT Gateways, and public Load Balancers.
- `02_premium_private_link_origin`: deployable Premium Front Door lab with a private Application Gateway listener, an unused compatibility public frontend, its generated Private Link service, and a private NGINX backend.

See [examples](examples/README.md).

## 🧠 Design Philosophy

- Regional origins and security/monitoring dependencies stay independently managed.
- Health, failover priority, load-balancing weight, and route relationships remain explicit.
- Private Link capability is present in the initial contract so private-origin blueprints need no breaking module redesign.
- Outputs are first-class composition points.

## 🧩 Related Modules & Training

- [terraform-az-fk-application-gateway](https://github.com/foggykitchen/terraform-az-fk-application-gateway)
- [terraform-az-fk-waf-policy](https://github.com/foggykitchen/terraform-az-fk-waf-policy)
- [terraform-az-fk-log-analytics](https://github.com/foggykitchen/terraform-az-fk-log-analytics)
- [foggykitchen-landing-zone-orchestrator](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator)

See [examples](examples/README.md) for progressive Front Door scenarios.

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
