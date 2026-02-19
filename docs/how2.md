# Como Usar

## Pré-requisitos

| Item | Requisito |
|------|-----------|
| Hardware | 3x Raspberry Pi 4 (4GB+) conectadas via Ethernet |
| Cartões SD | 3x microSD (16GB mínimo, Classe 10) |
| Leitor de cartão SD | Leitor USB compatível com Linux |
| Rede | Faixa de IPs estáticos disponível na sua rede local |
| Chave SSH | Par de chaves Ed25519 gerado (`ssh-keygen -t ed25519`) |
| Máquina host | Linux com `curl`, `xz`, `dd` e `ansible` instalados |

## Inventário

Edite o `inventory.yml` com seus IPs e hostnames antes de começar:

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

## Execução

Execute tudo a partir da raiz do projeto. Cada passo tem um script de validação que deve ser executado logo depois.

### Passo 1: Gravar cartões SD

Execute uma vez por Raspberry Pi. O script solicita IP, gateway, DNS, dispositivo e chave SSH.

```bash
./flashcard.sh
```

Use `--dry-run` para visualizar o que seria gravado sem tocar no cartão SD:

```bash
./flashcard.sh --dry-run
```

Insira o cartão SD na Pi, ligue-a e espere ela inicializar. Confirme a conectividade com `ping`.

### Passo 2: Instalar Python

```bash
ansible-playbook playbooks/bootstrap.yml
```

Validar:

```bash
./playbooks/bootstrap-validate.sh
```

### Passo 3: Preparar nodes

```bash
ansible-playbook playbooks/nodes.yml
```

Esse passo bloqueia o acesso SSH como root. Depois de executar, apenas o usuário `k3s` pode conectar.

Validar:

```bash
./playbooks/nodes-validate.sh
```

### Passo 4: Instalar K3s

```bash
ansible-playbook playbooks/k3s.yml
```

Validar:

```bash
./playbooks/k3s-validate.sh
```

## Estrutura do projeto

```
.
├── flashcard.sh               # Grava imagem Debian no cartão SD
├── inventory.yml              # Inventário Ansible com IPs dos nodes
├── ansible.cfg                # Configuração do Ansible
├── playbooks/
│   ├── bootstrap.yml          # Instala Python3
│   ├── bootstrap-validate.sh  # Valida o bootstrap
│   ├── nodes.yml              # Prepara nodes para K3s
│   ├── nodes-validate.sh      # Valida a preparação dos nodes
│   ├── k3s.yml                # Instala o cluster K3s
│   └── k3s-validate.sh        # Valida o cluster K3s
├── docs/                      # Documentação
└── banner/
    └── banner.png
```

## Solução de problemas

**Chave de host SSH mudou**: acontece depois de re-gravar um cartão. Corrija com:
```bash
ssh-keygen -R <ip>
```

**bootstrap.yml trava**: a Pi pode estar ainda inicializando. Espere 1-2 minutos depois de ligar antes de executar o playbook.

**Erro de lock do apt**: uma execução interrompida anterior o uma atualização automática pode ter travado o apt. Reinicie a Pi e tente novamente.
