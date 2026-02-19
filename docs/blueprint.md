# Cluster K3s em ARM – Documento de Arquitetura Técnica

## 1. Objetivo
Definir a arquitetura, premissas operacionais e decisões técnicas para implantação de cluster Kubernetes leve baseado em K3s em hardware ARM.

Este documento descreve decisões técnicas, justificativas, riscos e limitações.

## 2. Escopo

### Incluído:
- Cluster K3s em hardware ARM
- Automação via Ansible
- Hardening básico de sistema
- Rede IPv4
- Instalação não interativa

### Não incluído:
- Alta disponibilidade multi-datacenter
- Backup automatizado de etcd
- Observabilidade enterprise (Prometheus/Grafana)
- Gestão de secrets enterprise
- Conformidade regulatória (LGPD, ISO, etc.)

## 3. Premissas
- Ambiente IPv4-only
- Rede local confiável
- Sem exigência de HA distribuído
- Uso educacional, laboratório ou staging leve
- Operação por equipe técnica com acesso SSH via chave

## 4. Arquitetura

### 4.1 Hardware
- **Plataforma:** Raspberry Pi 4

#### Critérios:
- ARMv8 64-bit
- Até 8GB RAM
- Gigabit Ethernet real
- Baixo consumo energético

#### Risco:
- Não é hardware com ECC
- Sem SLA de fabricante
- Armazenamento via SD pode degradar

#### Mitigação:
- Uso de SD de alta qualidade
- Backup periódico
- Reprovisionamento automatizado

### 4.2 Sistema Operacional
- **Base:** Debian Trixie (testing) para ARM.

#### Motivação:
- Kernel recente
- Melhor suporte ARM
- Base mínima

#### Risco:
- Testing possui maior frequência de atualização
- Menor previsibilidade comparado ao Stable

#### Alternativa suportada:
- Debian Stable

### 4.3 Distribuição Kubernetes
- **Distribuição:** K3s

#### Critérios:
- Menor footprint
- Instalação simplificada
- Compatível com ARM
- Single binary
- SQLite padrão em single-node
- etcd embutido opcional em HA

#### Trade-off:
- Menos modular que kubeadm
- Abstração maior sobre componentes internos

#### Justificativa:
Para hardware limitado, kubeadm adiciona overhead operacional e de recursos.

## 5. Decisões de Sistema

### 5.1 Swap
- **Status:** Desabilitado.

#### Motivação:
- Aderência às recomendações oficiais do Kubernetes
- Previsibilidade de gerenciamento de memória

#### Risco:
- Sobrecarga pode gerar OOMKill

#### Mitigação:
- Dimensionamento adequado de pods
- Limites explícitos de memória

### 5.2 cgroups
- **Status:** Habilitado explicitamente.

#### Motivação:
- Garantir enforcement de limites de memória
- Compatibilidade consistente entre nodes

### 5.3 IPv6
- **Status:** Desabilitado.

#### Motivação:
- Ambiente exclusivamente IPv4
- Redução de complexidade operacional

#### Limitação:
- Não suporta dual-stack
- Não adequado para ambientes que exigem IPv6

### 5.4 WiFi
- **Status:** Desabilitado.

#### Motivação:
- Evitar múltiplas rotas
- Garantir tráfego exclusivo via Ethernet
- Manter previsibilidade de IP

## 6. Rede

### 6.1 IP Estático
Todos os nodes possuem IP estático.

#### Motivação:
- Evitar quebra de endpoints
- Estabilidade de certificados
- Previsibilidade de acesso

#### Risco:
- Mudança manual necessária se rede for alterada

### 6.2 DNS
- **Padrão:** 8.8.8.8 / 8.8.4.4 (Google)
- Configurável para ambientes corporativos.

#### Limitação:
- Pode ser bloqueado em redes empresariais

## 7. Automação
- **Ferramenta:** Ansible

### Princípios:
- Execução idempotente
- Totalmente não interativo
- Fail-fast
- Separação clara de fases

### Estrutura:
- **Bootstrap:**
  - Uso de raw até instalação do Python
  - `gather_facts: false` inicialmente
- **APT:**
  - Modo não interativo
  - Timers automáticos desabilitados
  - Prevenção de lock concorrente

## 8. Segurança

### Modelo de Acesso

| Estágio | Acesso SSH |
| :--- | :--- |
| Inicial | root via chave |
| Pós-configuração | usuário k3s via chave |
| Final | root SSH desabilitado |

### Controles:
- Sem senha
- Apenas autenticação por chave
- Sudo NOPASSWD para automação
- SSH root desabilitado após provisionamento

### Limitação:
- Não implementa MFA
- Não integra com IAM externo
- Não possui RBAC customizado além do padrão K3s

## 9. Validação

Validação independente via scripts shell:
- Verificação de swap
- Verificação de cgroups
- Estado do cluster
- Estado dos nodes
- Retorno via código 0/1 para integração com pipelines.

## 10. Riscos Conhecidos
- Falha de SD card
- Corrupção por desligamento abrupto
- Falta de HA se control plane único
- Sem backup automatizado de datastore
- Atualizações do Debian testing podem introduzir mudanças inesperadas

## 11. Não-Objetivos
Este projeto não pretende:
- Substituir ambiente Kubernetes corporativo
- Oferecer SLA
- Atender requisitos regulatórios
- Fornecer cluster multi-região

## 12. Princípios Arquiteturais
> Simplicidade > Complexidade
>
> Automação > Operação manual
>
> Previsibilidade > Flexibilidade
>
> Consistência entre nodes
>
> Reprovisionamento rápido em vez de troubleshooting prolongado