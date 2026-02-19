# ARM K3s Cluster – Technical Architecture Document

## 1. Objective
Define the architecture, operational premises, and technical decisions for deploying a lightweight Kubernetes cluster based on K3s on ARM hardware.

This document describes technical decisions, justifications, risks, and limitations.

## 2. Scope

### Included:
- K3s cluster on ARM hardware
- Automation via Ansible
- Basic system hardening
- IPv4 networking
- Non-interactive installation

### Not included:
- Multi-datacenter High Availability
- Automated etcd backup
- Enterprise observability (Prometheus/Grafana)
- Enterprise secrets management
- Regulatory compliance (GDPR, ISO, etc.)

## 3. Assumptions
- IPv4-only environment
- Trusted local network
- No distributed HA requirement
- Educational, lab, or light staging use
- Operation by technical team with SSH key access

## 4. Architecture

### 4.1 Hardware
- **Platform:** Raspberry Pi 4

#### Criteria:
- 64-bit ARMv8
- Up to 8GB RAM
- Real Gigabit Ethernet
- Low power consumption

#### Risk:
- Non-ECC hardware
- No manufacturer SLA
- SD storage may degrade

#### Mitigation:
- High-quality SD card usage
- Periodic backup
- Automated reprovisioning

### 4.2 Operating System
- **Base:** Debian Trixie (testing) for ARM.

#### Motivation:
- Recent kernel
- Better ARM support
- Minimal base

#### Risk:
- Testing has higher update frequency
- Lower predictability compared to Stable

#### Supported alternative:
- Debian Stable

### 4.3 Kubernetes Distribution
- **Distribution:** K3s

#### Criteria:
- Smaller footprint
- Simplified installation
- ARM compatible
- Single binary
- Standard SQLite in single-node
- Optional embedded etcd in HA

#### Trade-off:
- Less modular than kubeadm
- Higher abstraction over internal components

#### Justification:
For limited hardware, kubeadm adds operational and resource overhead.

## 5. System Decisions

### 5.1 Swap
- **Status:** Disabled.

#### Motivation:
- Adherence to official Kubernetes recommendations
- Memory management predictability

#### Risk:
- Overload may trigger OOMKill

#### Mitigation:
- Proper pod sizing
- Explicit memory limits

### 5.2 cgroups
- **Status:** Explicitly enabled.

#### Motivation:
- Ensure memory limit enforcement
- Consistent compatibility between nodes

### 5.3 IPv6
- **Status:** Disabled.

#### Motivation:
- Exclusively IPv4 environment
- Operational complexity reduction

#### Limitation:
- Does not support dual-stack
- Not suitable for environments requiring IPv6

### 5.4 WiFi
- **Status:** Disabled.

#### Motivation:
- Avoid multiple routes
- Ensure exclusive traffic via Ethernet
- Maintain IP predictability

## 6. Networking

### 6.1 Static IP
All nodes have static IP.

#### Motivation:
- Avoid endpoint breakage
- Certificate stability
- Access predictability

#### Risk:
- Manual change required if network changes

### 6.2 DNS
- **Default:** 8.8.8.8 / 8.8.4.4 (Google)
- Configurable for corporate environments.

#### Limitation:
- May be blocked in corporate networks

## 7. Automation
- **Tool:** Ansible

### Principles:
- Idempotent execution
- Fully non-interactive
- Fail-fast
- Clear separation of phases

### Structure:
- **Bootstrap:**
  - Use of raw until Python installation
  - `gather_facts: false` initially
- **APT:**
  - Non-interactive mode
  - Automatic timers disabled
  - Concurrent lock prevention

## 8. Security

### Access Model

| Stage | SSH Access |
| :--- | :--- |
| Initial | root via key |
| Post-config | k3s user via key |
| Final | root SSH disabled |

### Controls:
- Passwordless
- Key-based authentication only
- Sudo NOPASSWD for automation
- Root SSH disabled after provisioning

### Limitation:
- Does not implement MFA
- Does not integrate with external IAM
- No custom RBAC beyond K3s default

## 9. Validation

Independent validation via shell scripts:
- Swap verification
- cgroups verification
- Cluster state
- Node state
- Return via 0/1 code for pipeline integration.

## 10. Known Risks
- SD card failure
- Corruption due to abrupt shutdown
- Lack of HA if single control plane
- No automated datastore backup
- Debian testing updates may introduce unexpected changes

## 11. Non-Goals
This project does not intend to:
- Replace enterprise Kubernetes environment
- Offer SLA
- Meet regulatory requirements
- Provide multi-region cluster

## 12. Architectural Principles
> Simplicity > Complexity
>
> Automation > Manual operation
>
> Predictability > Flexibility
>
> Consistency between nodes
>
> Rapid reprovisioning instead of prolonged troubleshooting
