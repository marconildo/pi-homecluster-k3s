# Cómo Usar

## Requisitos previos

| Ítem | Requisito |
|------|-----------|
| Hardware | 3x Raspberry Pi 4 (4GB+) conectadas vía Ethernet |
| Tarjetas SD | 3x microSD (16GB mínimo, Clase 10) |
| Lector de tarjetas SD | Lector USB compatible con Linux |
| Red | Rango de IP estáticas disponible en tu red local |
| Clave SSH | Par de claves Ed25519 generado (`ssh-keygen -t ed25519`) |
| Máquina host | Linux con `curl`, `xz`, `dd` y `ansible` instalados |

## Inventario

Edita `inventory.yml` con tus IPs y hostnames antes de empezar:

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

## Ejecución

Ejecuta todo desde la raíz del proyecto. Cada paso tiene un script de validación que debe ejecutarse inmediatamente después.

### Paso 1: Flashear tarjetas SD

Ejecuta una vez por Raspberry Pi. El script solicita IP, gateway, DNS, dispositivo y clave SSH.

```bash
./flashcard.sh
```

Usa `--dry-run` para previsualizar qué se escribiría sin tocar la tarjeta SD:

```bash
./flashcard.sh --dry-run
```

Inserta la tarjeta SD en la Pi, enciéndela y espera a que arranque. Confirma la conectividad con `ping`.

### Paso 2: Instalar Python

```bash
ansible-playbook playbooks/bootstrap.yml
```

Validar:

```bash
./playbooks/bootstrap-validate.sh
```

### Paso 3: Preparar nodos

```bash
ansible-playbook playbooks/nodes.yml
```

Este paso bloqueia el acceso SSH como root. Después de ejecutarse, solo el usuario `k3s` puede conectarse.

Validar:

```bash
./playbooks/nodes-validate.sh
```

### Paso 4: Instalar K3s

```bash
ansible-playbook playbooks/k3s.yml
```

Validar:

```bash
./playbooks/k3s-validate.sh
```

## Estructura del proyecto

```
.
├── flashcard.sh               # Flashea imagen Debian a la tarjeta SD
├── inventory.yml              # Inventario Ansible con IPs de los nodos
├── ansible.cfg                # Configuración de Ansible
├── playbooks/
│   ├── bootstrap.yml          # Instala Python3
│   ├── bootstrap-validate.sh  # Valida el bootstrap
│   ├── nodes.yml              # Prepara nodos para K3s
│   ├── nodes-validate.sh      # Valida la preparación de nodos
│   ├── k3s.yml                # Instala el clúster K3s
│   └── k3s-validate.sh        # Valida el clúster K3s
├── docs/                      # Documentación
└── banner/
    └── banner.png
```

## Solución de problemas

**Clave de host SSH cambió**: ocurre después de re-flashear una tarjeta. Solución:
```bash
ssh-keygen -R <ip>
```

**bootstrap.yml se cuelga**: la Pi puede estar aún arrancando. Espera 1-2 minutos después de encenderla antes de ejecutar el playbook.

**Error de lock de apt**: una ejecución interrumpida anterior o una actualización automática puede haber bloqueado apt. Reinicia la Pi e intenta de nuevo.
