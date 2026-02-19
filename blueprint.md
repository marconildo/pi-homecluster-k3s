# Detalhamento Técnico do Projeto

A ideia deste documento é explicar os porquês das decisões técnicas e da arquitetura do cluster, dissecando o que de fato acontece durante o provisionamento de forma transparente e direta. Se você quer entender como as peças se encaixam desde o preparo do SD card até a comunicação do control plane com os workers, você está no lugar certo.

## A Abordagem do Flashcard

O script `flashcard.sh` é o verdadeiro ponto de partida. Por que criar um script Bash do zero ao invés de usar utilitários visuais como o Raspberry Pi Imager? 

O principal motivo é o zero atrito e a automação total. Ao invés de uma imagem agnóstica precisando de customizações em chassi, nós usamos a versão enxuta "tested" do Debian instalando configurações cirúrgicas e vitais dentro da Partição Root de forma antecipada. A placa já fará o seu primeiro boot operando exatamente onde e como precisamos.

| Ação Injetada | Por que é importante? |
| :--- | :--- |
| **Rede Estática** | O arquivo `/etc/network/interfaces.d/eth0` garante que seu node consiga o exato endereço de rede previamente escolhido, fundamental para o Ansible ter os alvos organizados em formato de inventário na fase seguinte. |
| **APT Não-interativo** | A modificação do APT com as diretivas `Assume-Yes` e `force-yes` força o gerenciador de pacotes a não paralisar processos esperando confirmações de teclado do usuário. |
| **Chave SSH** | Não trabalhamos com senhas soltas para os nossos dispositivos. Apenas a sua máquina possui o material criptográfico (privado) correspondente à chave pública provisionada. |
| **Timers do APT** | Excluir os timers que verificam atualizações assim que o Debian acorda (`apt-daily.timer` e `apt-daily-upgrade.timer`) evita que o administrador sofra com os temidos travamentos de base de dados tentando gerenciar a instalação das ferramentas base do Ansible nos segundos iniciais de vida do sistema operacional. |

## Orquestração Sistêmica com Ansible

Logo após as Raspberry Pis terem ligado, nós dispomos de sistemas Linux praticamente virgens, mas muito bem situados com rede e chaves seguras. A magia agora reside inteiramente nos playbooks.

### O Paradoxo do Bootstrap

Para o Ansible trabalhar de vento em popa explorando todos os seus módulos de automação maduros, o endpoint necessita da presença de uma base Python na ponta final da comunicação (dentro dos nodes). Mas como vamos usar playbooks do Ansible em sistemas operacionais que sequer possuem a linguagem instalada de fábrica?

A resolução aparece no playbook `bootstrap.yml` junto de um design pattern astuto do utilitário Ansible: o uso da modelagem através do módulo sintático `raw`. O módulo instrui as máquinas através de sessões em modo bruto e direto ao shell remoto, não exigindo pré-requisitos sofisticados onde uma singela conexão SSH basta. Em poucos passos, o próprio `apt` engole os binários do `python3`, trazendo o cluster nas sombras para um plano padronizado onde a automação real pode brilhar.

### Preparação do Terreno Sistêmico

O playbook `nodes.yml` atua como um pedreiro preparando o alicerce fundamental para comportar as turbulências da nossa infraestrutura de containers final. Dividimos em fases operacionais estritas:

| Fase Operacional | Atuação do Ansible | Significado e Efeito Funcional |
| :--- | :--- | :--- |
| Instalações Base | Instala pacotes críticos da administração diária (`sudo`, `htop`, `git`, `timesyncd`, etc). | Além da base sistêmica, forçar o empacotamento do serviço de sincronização do relógio Linux torna eventos de rede mais saudáveis e organizáveis. |
| Criação de Permissões | Assenta e configura os diretórios corretos do próprio usuário nomeado `k3s`. | Deixar de utilizar o root sistêmico o mais cedo possível diminui vertiginosamente grandes chances de um acidente ou exploração não dimensionados pelo serviço e usuário base. |
| Controle de Kernel | Modifica o `/boot/firmware/cmdline.txt` habilitando a flag de controle modular `cgroup_memory`. | Instâncias Kubernetes dependem integralmente dessa permissão lógica para impor limites sobre o gasto excessivo do tráfego interno dos containers das aplicações. |
| Desarme de Variáveis | Enrijece e suspende o fluxo das memórias virtuais atrelando ações diretas contra partições Swap. | O ecossistema container atual trabalha agressivamente com arquiteturas voltadas ao limite purista de memória volátil verdadeira. Swap traz atrasos de barramento de I/O em cartões micro-SD. |
| Ponto de Não Retorno | Elimina explicitamente qualquer abertura de rede utilizando autorizações fracas nos arquivos do gerador de acessos segurados via chave ou usuário administrador total (o su su). | Todo o provisionamento pós esse momento dependerá singularmente das chaves criptografadas providas com cautela e do utilitário base recém-nascido. |

O modelo de comportamento ideal não se finaliza sem eventuais recargas elétricas (reboots). O playbook é inteligentemente parametrizado a acioná-las contra os próprios terminais caso julgue imprescindível aplicar com profundidade modificações nos esquemas do sistema de boot.

## A Arquitetura do K3s

O arranjo do cume operacional, orquestrado pela rotina `k3s.yml`, encerra a coreografia de máquinas instanciando nossa topologia orquestrada real do mundo contêinerizado. O principal motivador desta formatação singular repousa na hierarquização determinística e sequencial em lugar da execução ampla e assíncrona contra múltiplos perfis.

| Estágio do K3s | Funcionamento e Responsabilidade Técnica |
| :--- | :--- |
| **Instalação do Control_Plane** | O Ansible seleciona minuciosamente apenas quem deve abrigar o núcleo primordial. Ele garante o download e construção do servidor central (Control Plane), averiguando seu status e colhendo chaves seguras locais conhecidas como um "Token de Associação". |
| **Registro dos Workers** | Mantendo o IP gerencial recém consolidado do núcleo primário em mãos bem com esse Token obtido, passamos ao esquadrão de workers ordenando que estes busquem pelos manifestos originais e formem a rede associativa lateral, convertendo servidores solitários em braços armados dos serviços e processos sob total comando dos supervisores. |
| **Validações Clusterizadas** | Retornaremos à camada do master plane verificando sem tréguas pelas transições do status "Ready" atrelada ao ecossistema global interno de registros das tabelas operacionais distribuídas no K3s. O projeto também rotula explicitamente sob métricas organizativas nativas, categorizando adequadamente a infraestrutura dos seus processadores virtuais unificados. |

O cluster emerge finalmente do anonimato elétrico de hardware e converte pacotes simples via terminais num bloco lógico operante, mantendo a documentação e histórico inteiramente legíveis pela própria sintaxe embutida. Tudo de fato escalável, versionável e simples.

<br>

*Nota: Esta documentação foi gerada pelo modelo de IA Gemini 3.1 Pro.*
