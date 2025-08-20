# HA NAT Gateay
Exoscale NAT Gateway with VRRP (Terraform)

This Terraform project provisions a highly available NAT Gateway using two Ubuntu 22.04 instances with:
 * Private network
 * IP forwarding & NAT (iptables)
 * High Availability using VRRP (keepalived)
 * Anti-affinity group to avoid both nodes running on the same physical host

Features
 * Two gateway nodes in an Exoscale private network
 * VRRP virtual IP (keepalived) for automatic failover
 * NAT masquerading using iptables
 * Security group with restricted SSH access
 * Cloud-Init configuration for automated setup

Variables
 | Variable              | Description                                       | Example           |
| --------------------- | ------------------------------------------------- | ----------------- |
| `project`             | Project prefix for resources                      | `my-natgw`        |
| `exoscale_api_key`    | Exoscale API key                                  | `EXOxxxxxxxx`     |
| `exoscale_api_secret` | Exoscale API secret                               | `yyyyyyyy`        |
| `zone`                | Exoscale zone                                     | `de-muc-1`        |
| `ip_node_one`         | Private IP of node 1                              | `10.0.0.2`        |
| `ip_node_two`         | Private IP of node 2                              | `10.0.0.3`        |
| `ip_netmask`          | Network mask (CIDR suffix)                        | `24`              |
| `ip_vrrp`             | Shared Virtual IP (VIP) for VRRP                  | `10.0.0.1`        |
| `vrrp_auth_pass`      | Password for VRRP authentication                  | `SuperSecretPass` |
| `mgm_ip`              | Management IP/range allowed for SSH (CIDR format) | `<YOUR-IP>/32`    |

Apply configuration with inline variables
    terraform apply \
    -var="project=my-natgw" \
    -var="exoscale_api_key=EXOxxxxxxxx" \
    -var="exoscale_api_secret=yyyyyyyyyyyy" \
    -var="zone=at-vie-2" \
    -var="ip_node_one=10.0.0.2" \
    -var="ip_node_two=10.0.0.3" \
    -var="ip_netmask=24" \
    -var="ip_vrrp=10.0.0.1" \
    -var="vrrp_auth_pass=SuperSecretPass" \
    -var="mgm_ip=<YOUR-IP>/32"
