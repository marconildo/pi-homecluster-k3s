# How to Use

## Prerequisites

| Item | Requirement |
|------|-------------|
| Hardware | 3x Raspberry Pi 4 (4GB+) connected via Ethernet |
| SD Cards | 3x microSD (16GB minimum, Class 10) |
| SD Card Reader | USB card reader compatible with Linux |
| Network | Static IP range available on your local network |
| SSH Key | Ed25519 key pair generated (`ssh-keygen -t ed25519`) |
| Host machine | Linux with `curl`, `xz`, `dd`, and `ansible` installed |

## Inventory

Edit `inventory.yml` with your IPs and hostnames before starting:

```yaml
all:
  children:
    control_plane:
      hosts:
        controlplane:
          ansible_host: 192.168.18.240
          hostname: controlplane
    workers:
      hosts:
        worker01:
          ansible_host: 192.168.18.242
          hostname: worker01
        worker02:
          ansible_host: 192.168.18.244
          hostname: worker02
  vars:
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

## Execution

Run everything from the project root. Each step has a validation script that should be run immediately after.

### Step 1: Flash SD cards

Run once per Raspberry Pi. The script asks for IP, gateway, DNS, device, and SSH key.

```bash
./flashcard.sh
```

Use `--dry-run` to preview what would be written without touching the SD card:

```bash
./flashcard.sh --dry-run
```

Insert the SD card into the Pi, power it on, and wait for it to boot. Confirm connectivity with `ping`.

### Step 2: Install Python

```bash
ansible-playbook playbooks/bootstrap.yml
```

Validate:

```bash
./playbooks/bootstrap-validate.sh
```

### Step 3: Prepare nodes

```bash
ansible-playbook playbooks/nodes.yml
```

This step blocks root SSH access. After it runs, only the `k3s` user can connect.

Validate:

```bash
./playbooks/nodes-validate.sh
```

### Step 4: Install K3s

```bash
ansible-playbook playbooks/k3s.yml
```

Validate:

```bash
./playbooks/k3s-validate.sh
```

## Project Structure

```
.
├── flashcard.sh               # Flashes Debian image to SD card
├── inventory.yml              # Ansible inventory with node IPs
├── ansible.cfg                # Ansible configuration
├── playbooks/
│   ├── bootstrap.yml          # Installs Python3
│   ├── bootstrap-validate.sh  # Validates bootstrap
│   ├── nodes.yml              # Prepares nodes for K3s
│   ├── nodes-validate.sh      # Validates node preparation
│   ├── k3s.yml                # Installs K3s cluster
│   └── k3s-validate.sh        # Validates K3s cluster
├── docs/                      # Documentation
└── banner/
    └── banner.png
```

## Troubleshooting

**SSH host key changed**: happens after re-flashing a card. Fix with:
```bash
ssh-keygen -R <ip>
```

**bootstrap.yml hangs**: the Pi may still be booting. Wait 1-2 minutes after powering on before running the playbook.

**apt lock error**: a previous interrupted run or automatic update may have locked apt. Reboot the Pi and try again.
