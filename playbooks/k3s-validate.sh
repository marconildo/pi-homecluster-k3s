#!/bin/bash
# Validador do k3s.yml.
# Verifica via SSH se o cluster K3s esta operacional.
# Conecta como k3s e valida server, agents, nodes Ready, e CoreDNS.
# Deve ser executado da raiz do projeto.

# ==========================================
# Variaveis
# ==========================================

INVENTORY="inventory.yml"
CONTROLPLANE=$(grep -A1 'controlplane:' "$INVENTORY" | grep 'ansible_host:' | awk '{print $2}' | head -1)
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
# Validar cluster
# ==========================================

echo ""
echo "========================================"
echo "  Validacao K3s Cluster"
echo "========================================"

# K3s server no controlplane
echo ""
echo "--- Control Plane: $CONTROLPLANE ---"

SERVER=$(ssh_run $CONTROLPLANE "sudo systemctl is-active k3s")
check "K3s server ativo" "$SERVER" "active"

# Listar nodes do cluster
NODES_OUTPUT=$(ssh_run $CONTROLPLANE "sudo k3s kubectl get nodes --no-headers 2>/dev/null")

# Verificar cada node
for NODE in $NODES; do
    echo ""
    echo "--- Node: $NODE ---"

    if [ "$NODE" = "$CONTROLPLANE" ]; then
        HOSTNAME=$(ssh_run $NODE "hostname")
        check "Node presente no cluster" "$NODES_OUTPUT" "$HOSTNAME"
        check "Node esta Ready" "$(echo "$NODES_OUTPUT" | grep "$HOSTNAME")" " Ready"
    else
        AGENT=$(ssh_run $NODE "sudo systemctl is-active k3s-agent")
        check "K3s agent ativo" "$AGENT" "active"

        HOSTNAME=$(ssh_run $NODE "hostname")
        check "Node presente no cluster" "$NODES_OUTPUT" "$HOSTNAME"
        check "Node esta Ready" "$(echo "$NODES_OUTPUT" | grep "$HOSTNAME")" " Ready"
    fi
done

# CoreDNS
echo ""
echo "--- CoreDNS ---"
COREDNS=$(ssh_run $CONTROLPLANE "sudo k3s kubectl get pods -n kube-system --no-headers 2>/dev/null | grep coredns")
check "CoreDNS esta Running" "$COREDNS" "Running"

# ==========================================
# Consulta real
# ==========================================

echo ""
echo "--- Status do Cluster ---"
ssh_run $CONTROLPLANE "sudo k3s kubectl get nodes -o wide 2>/dev/null"

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
