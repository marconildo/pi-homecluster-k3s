# Ansible Cheatsheet

All ad-hoc commands require `-u k3s` to connect with the correct user.

## Ad-hoc Commands

```bash
# Ping all nodes
ansible all -m ping -u k3s

# Run command on all nodes
ansible all -m raw -a "uptime" -u k3s

# Run shell command
ansible all -m shell -a "hostname" -u k3s

# View facts from a node (RAM, CPU, OS, etc.)
ansible controlplane -m setup -u k3s

# Run only on workers
ansible workers -m shell -a "sudo systemctl status k3s-agent" -u k3s

# Run only on controlplane
ansible controlplane -m shell -a "sudo k3s kubectl get nodes" -u k3s
```

## Useful Flags

| Flag | Description |
|------|-------------|
| `-u k3s` | SSH user |
| `-m ping` | module to use (ping, shell, raw, setup, copy, apt...) |
| `-a "cmd"` | argument for the module |
| `-b` | become (escalate to root via sudo) |
| `-v` to `-vvvv` | verbosity (debug) |

## Playbooks

```bash
# Test without executing (dry-run)
ansible-playbook playbooks/nodes.yml --check

# Run from a specific task
ansible-playbook playbooks/nodes.yml --start-at-task="Configure hostname"

# See which hosts would be affected
ansible-playbook playbooks/nodes.yml --list-hosts

# See which tasks would be executed
ansible-playbook playbooks/nodes.yml --list-tasks

# Verbosity
ansible-playbook playbooks/nodes.yml -v
ansible-playbook playbooks/nodes.yml -vvvv
```

## Inventory

```bash
# View all hosts in JSON
ansible-inventory --list

# View in graph format
ansible-inventory --graph
```
