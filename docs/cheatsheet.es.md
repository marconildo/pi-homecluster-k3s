# Cheatsheet de Ansible

Todos los comandos ad-hoc necesitan `-u k3s` para conectar con el usuario correcto.

## Comandos ad-hoc

```bash
# Ping en todos los nodos
ansible all -m ping -u k3s

# Ejecutar comando en todos los nodos
ansible all -m raw -a "uptime" -u k3s

# Ejecutar comando shell
ansible all -m shell -a "hostname" -u k3s

# Ver facts de un nodo (RAM, CPU, OS, etc.)
ansible controlplane -m setup -u k3s

# Ejecutar solo en workers
ansible workers -m shell -a "sudo systemctl status k3s-agent" -u k3s

# Ejecutar solo en controlplane
ansible controlplane -m shell -a "sudo k3s kubectl get nodes" -u k3s
```

## Flags útiles

| Flag | Descripción |
|------|-------------|
| `-u k3s` | usuario SSH |
| `-m ping` | módulo a usar (ping, shell, raw, setup, copy, apt...) |
| `-a "cmd"` | argumento para el módulo |
| `-b` | become (escalar a root vía sudo) |
| `-v` a `-vvvv` | verbosidad (debug) |

## Playbooks

```bash
# Probar sin ejecutar (dry-run)
ansible-playbook playbooks/nodes.yml --check

# Ejecutar desde una task específica
ansible-playbook playbooks/nodes.yml --start-at-task="Configurar hostname"

# Ver qué hosts serían afectados
ansible-playbook playbooks/nodes.yml --list-hosts

# Ver qué tasks serían ejecutadas
ansible-playbook playbooks/nodes.yml --list-tasks

# Verbosidad
ansible-playbook playbooks/nodes.yml -v
ansible-playbook playbooks/nodes.yml -vvvv
```

## Inventario

```bash
# Ver todos los hosts en JSON
ansible-inventory --list

# Ver en formato gráfico
ansible-inventory --graph
```
