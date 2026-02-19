#!/bin/bash
# Validador do nodes.yml.
# Verifica via SSH se todos os pre-requisitos para K3s estao configurados.
# Conecta como k3s porque o usuario ja existe neste ponto.
# Deve ser executado da raiz do projeto.

# ==========================================
# Variaveis
# ==========================================

INVENTORY="inventory.yml"
NODES=$(grep 'ansible_host:' "$INVENTORY" | awk '{print $2}')
KEY="$HOME/.ssh/id_ed25519"
PASS=0
FAIL=0

# ==========================================
# Funcoes
# ==========================================

ssh_run() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
        -i $KEY k3s@$1 "$2" 2>/dev/null
}

check() {
    DESC=$1
    RESULT=$2
    EXPECTED=$3

    if echo "$RESULT" | grep -q "$EXPECTED"; then
        echo "  ✅ $DESC"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $DESC"
        echo "     Esperado: $EXPECTED"
        echo "     Obtido:   $RESULT"
        FAIL=$((FAIL + 1))
    fi
}

# ==========================================
# Validar cada node
# ==========================================

echo ""
echo "========================================"
echo "  Validacao Nodes"
echo "========================================"

for NODE in $NODES; do
    echo ""
    echo "--- Node: $NODE ---"

    # Hostname
    HOSTNAME=$(ssh_run $NODE "hostname")
    check "Hostname configurado" "$HOSTNAME" "controlplane\|worker01\|worker02"

    # Swap
    SWAP=$(ssh_run $NODE "sudo swapon --show")
    if [ -z "$SWAP" ]; then
        echo "  ✅ Swap desabilitado"
        PASS=$((PASS + 1))
    else
        echo "  ❌ Swap ainda ativo: $SWAP"
        FAIL=$((FAIL + 1))
    fi

    # Cgroups
    CGROUPS=$(ssh_run $NODE "cat /boot/firmware/cmdline.txt")
    check "Cgroups habilitado" "$CGROUPS" "cgroup_memory=1"

    # IPv6
    IPV6=$(ssh_run $NODE "cat /proc/sys/net/ipv6/conf/all/disable_ipv6")
    check "IPv6 desabilitado" "$IPV6" "1"

    # NTP
    NTP=$(ssh_run $NODE "timedatectl status")
    check "NTP sincronizado" "$NTP" "synchronized: yes"

    # Timezone
    TZ=$(ssh_run $NODE "timedatectl status")
    check "Timezone America/Sao_Paulo" "$TZ" "Sao_Paulo"

    # Sudo sem senha
    SUDO=$(ssh_run $NODE "sudo whoami")
    check "Sudo sem senha" "$SUDO" "root"

    # Root SSH bloqueado
    ROOT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
        -i $KEY root@$NODE "echo OK" 2>&1)
    if echo "$ROOT" | grep -q "Permission denied"; then
        echo "  ✅ Root SSH bloqueado"
        PASS=$((PASS + 1))
    else
        echo "  ❌ Root SSH ainda acessivel!"
        FAIL=$((FAIL + 1))
    fi

    # Pacotes instalados
    for PKG in htop ncdu git nano iptables; do
        INSTALLED=$(ssh_run $NODE "dpkg -l $PKG 2>/dev/null | grep '^ii'")
        check "Pacote instalado: $PKG" "$INSTALLED" "ii"
    done
done

# ==========================================
# Consulta real
# ==========================================

echo ""
echo "--- Resumo dos nodes ---"
printf "  %-14s %-10s %-8s %-20s\n" "HOSTNAME" "IP" "SWAP" "TIMEZONE"
for NODE in $NODES; do
    HOSTNAME=$(ssh_run $NODE "hostname")
    SWAP_STATUS=$(ssh_run $NODE "sudo swapon --show")
    if [ -z "$SWAP_STATUS" ]; then SWAP_STATUS="off"; else SWAP_STATUS="ON"; fi
    TZ=$(ssh_run $NODE "timedatectl show -p Timezone --value")
    printf "  %-14s %-10s %-8s %-20s\n" "$HOSTNAME" "$NODE" "$SWAP_STATUS" "$TZ"
done

# ==========================================
# Resultado
# ==========================================

echo ""
echo "========================================"
echo "  Resultado Final"
echo "========================================"
echo "  ✅ Passou: $PASS"
echo "  ❌ Falhou: $FAIL"
echo "========================================"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
