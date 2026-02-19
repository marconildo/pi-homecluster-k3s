# Ansible Cheatsheet

Todos os comandos ad-hoc precisam de `-u k3s` para conectar com o usuario correto.

## Comandos ad-hoc

```bash
# Ping em todos os nodes
ansible all -m ping -u k3s

# Rodar comando em todos os nodes
ansible all -m raw -a "uptime" -u k3s

# Rodar comando shell
ansible all -m shell -a "hostname" -u k3s

# Ver fatos de um node (RAM, CPU, OS, etc.)
ansible controlplane -m setup -u k3s

# Rodar so nos workers
ansible workers -m shell -a "sudo systemctl status k3s-agent" -u k3s

# Rodar so no controlplane
ansible controlplane -m shell -a "sudo k3s kubectl get nodes" -u k3s
```

## Flags uteis

| Flag | Descricao |
|------|-----------|
| `-u k3s` | usuario SSH |
| `-m ping` | modulo a usar (ping, shell, raw, setup, copy, apt...) |
| `-a "cmd"` | argumento pro modulo |
| `-b` | become (escalar pra root via sudo) |
| `-v` a `-vvvv` | verbosidade (debug) |

## Playbooks

```bash
# Testar sem executar (dry-run)
ansible-playbook playbooks/nodes.yml --check

# Rodar a partir de uma task especifica
ansible-playbook playbooks/nodes.yml --start-at-task="Configurar hostname"

# Ver quais hosts seriam afetados
ansible-playbook playbooks/nodes.yml --list-hosts

# Ver quais tasks seriam executadas
ansible-playbook playbooks/nodes.yml --list-tasks

# Verbosidade
ansible-playbook playbooks/nodes.yml -v
ansible-playbook playbooks/nodes.yml -vvvv
```

## Inventario

```bash
# Ver todos os hosts em JSON
ansible-inventory --list

# Ver em formato grafico
ansible-inventory --graph
```
