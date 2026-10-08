# Azure Front Door with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-frontdoor** module.
The examples are designed as **incremental building blocks**, starting from public priority-based failover and then introducing a Premium Private Link origin.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and are intended for Azure and multicloud courses focused on global application delivery and disaster recovery.

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| 01 | **Public Priority Failover** | Standard Front Door, two regional VNets, private NGINX VMs, NAT Gateways, public Load Balancers, primary/standby priority |
| 02 | **Premium Private Link Origin** | Premium Front Door, private Application Gateway listener, Private Link service, private NGINX backend, managed private endpoint request |

Each example builds on the **concepts** introduced in the previous one, but can be applied independently for learning and experimentation.

---

## ⚙️ How to Use

Each example directory contains:

- Terraform/OpenTofu configuration (`.tf`)
- A focused `README.md` explaining the goal of the example
- A safe `terraform.tfvars.example` without credentials or secrets
- A minimal architecture centered on one Front Door capability
- Reserved architecture and Azure Portal screenshot sections for deployment evidence

To run the first example later:

```bash
cd examples/01_public_priority_failover
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
tofu apply
```

The recommended learning sequence is:
01 → 02

Example 01 has been deployed, tested, documented, and destroyed. Example 02 has been deployed and tested end-to-end; its architecture diagram and reproducible Azure CLI, cURL, and OpenTofu test results are documented in the example README. Azure Portal screenshots will be added after collection.

---

## 🧩 Design Principles

- One example = one architectural goal
- Explicit health probes and failover priority
- The root module keeps regional origins independently managed; each example composes complete disposable origins for end-to-end learning
- Existing dependency IDs and host names are explicit inputs
- No secrets or subscription-specific values in source control
- Static validation is not represented as successful runtime deployment

These examples intentionally avoid:

- Full landing zones
- Database replication
- Hidden dependencies between examples
- Creating regional origin infrastructure inside the root Front Door module
- Creating Log Analytics workspaces or Front Door WAF policies

---

## 🧩 Related Resources

- [FoggyKitchen Azure Front Door Module (terraform-az-fk-frontdoor)](../)
- [FoggyKitchen Azure Application Gateway Module (terraform-az-fk-application-gateway)](https://github.com/foggykitchen/terraform-az-fk-application-gateway)
- [FoggyKitchen Azure WAF Policy Module (terraform-az-fk-waf-policy)](https://github.com/foggykitchen/terraform-az-fk-waf-policy)
- [Azure Front Door Private Link documentation](https://learn.microsoft.com/azure/frontdoor/private-link)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
