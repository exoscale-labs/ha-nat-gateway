variable "project" { }
variable "exoscale_api_key" { }
variable "exoscale_api_secret" { }
variable "zone" { }
variable "ip_node_one" {}
variable "ip_node_two" {}
variable "ip_netmask" {}
variable "ip_vrrp" {}
variable "vrrp_auth_pass" {}
variable "mgm_ip" {}

terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
    }
  }
}


provider "exoscale" {
  key    = "${var.exoscale_api_key}"
  secret = "${var.exoscale_api_secret}"
}

data "exoscale_template" "ubuntu_template" {
  zone = "${var.zone}"
  name = "Linux Ubuntu 22.04 LTS 64-bit"
}

resource "exoscale_security_group" "maintenance" {
  name = "${var.project}-natgateway"
}

resource "exoscale_anti_affinity_group" "sos-affinity-group" {
  name        = "${var.project}-natgateway-affinity"
  description = "Prevent compute instances to run on the same host"
}

resource "exoscale_security_group_rule" "ssh-access" {
  security_group_id = exoscale_security_group.maintenance.id
  type = "INGRESS"
  protocol = "TCP"
  start_port = "22"
  end_port = "22"
  cidr = "${var.mgm_ip}"
}

resource "exoscale_private_network" "natgateway-network" {
  zone = "${var.zone}"
  name = "${var.project}-natgateway-network"
}

resource "exoscale_compute_instance" "gateway-node1" {
  zone = "${var.zone}"
  name = "${var.project}-natgateway-node1"

  template_id = data.exoscale_template.ubuntu_template.id
  anti_affinity_group_ids = [exoscale_anti_affinity_group.sos-affinity-group.id]
  security_group_ids = [exoscale_security_group.maintenance.id]
  type        = "standard.small"
  disk_size   = 10
  ssh_key = "<YOUR-SSH-KEY>"
  network_interface {
    network_id = exoscale_private_network.natgateway-network.id
  }
  user_data = <<EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - iptables-persistent
  - keepalived
write_files:
- path: /etc/netplan/internal-network.yaml
  permissions: '0644'
  content: |
    network:
        version: 2
        renderer: networkd
        ethernets:
            eth1:
                addresses:
                  - ${var.ip_node_one}/${var.ip_netmask}
- path: /etc/sysctl.d/99_ip-forwarding.conf
  permissions: '0644'
  content: |
    net.ipv4.ip_forward=1
    #net.ipv6.conf.all.forwarding=1
- path: /etc/keepalived/keepalived.conf
  permissions: '0644'
  content: |
    vrrp_instance failover_link
    {
      state MASTER
      interface eth1
      virtual_router_id 15
      priority 100
      advert_int 4
      authentication {
        auth_type AH
        auth_pass ${var.vrrp_auth_pass}
      }
      virtual_ipaddress {
        ${var.ip_vrrp} dev eth1 label eth1:1
      }
    }
runcmd:
  - netplan generate
  - netplan apply
  - sysctl -w net.ipv4.ip_forward=1
  - iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE
  - iptables-save > /etc/iptables/rules.v4
  - systemctl enable keepalived
  - systemctl start keepalived
  - /usr/sbin/reboot
EOF
}

resource "exoscale_compute_instance" "gateway-node2" {
  zone = "${var.zone}"
  name = "${var.project}-natgateway-node2"

  template_id = data.exoscale_template.ubuntu_template.id
  anti_affinity_group_ids = [exoscale_anti_affinity_group.sos-affinity-group.id]
  security_group_ids = [exoscale_security_group.maintenance.id]
  type        = "standard.small"
  disk_size   = 10
  ssh_key = "<YOUR-SSH-KEY>"
  network_interface {
    network_id = exoscale_private_network.natgateway-network.id
  }
  user_data = <<EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - iptables-persistent
  - keepalived
write_files:
- path: /etc/netplan/internal-network.yaml
  permissions: '0644'
  content: |
    network:
        version: 2
        renderer: networkd
        ethernets:
            eth1:
                addresses:
                    - ${var.ip_node_two}/${var.ip_netmask}
- path: /etc/sysctl.d/99_ip-forwarding.conf
  permissions: '0644'
  content: |
    net.ipv4.ip_forward=1
    #net.ipv6.conf.all.forwarding=1
- path: /etc/keepalived/keepalived.conf
  permissions: '0644'
  content: |
    vrrp_instance failover_link
    {
      state MASTER
      interface eth1
      virtual_router_id 15
      priority 110
      advert_int 4
      authentication {
        auth_type AH
        auth_pass ${var.vrrp_auth_pass}
      }
      virtual_ipaddress {
        ${var.ip_vrrp} dev eth1 label eth1:1
      }
    }
runcmd:
  - netplan generate
  - netplan apply
  - sysctl -w net.ipv4.ip_forward=1
  - iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE
  - iptables-save > /etc/iptables/rules.v4
  - systemctl enable keepalived
  - systemctl start keepalived
  - /usr/sbin/reboot
EOF
}