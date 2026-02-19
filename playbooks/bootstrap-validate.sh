#!/bin/bash
# Validador do bootstrap.yml.
# Verifica via SSH se o Python3 foi instalado em todos os nodes.
# Conecta como root porque o usuario k3s ainda nao existe neste ponto.
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
        -i $KEY root@$1 "$2" 2>/dev/null
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
echo "  Validacao Bootstrap"
echo "========================================"

for NODE in $NODES; do
    echo ""
    echo "--- Node: $NODE ---"

    # Conectividade SSH
    SSH=$(ssh_run $NODE "echo OK")
    if [ "$SSH" = "OK" ]; then
        echo "  ✅ SSH acessivel"
        PASS=$((PASS + 1))
    else
        echo "  ❌ SSH nao acessivel"
        FAIL=$((FAIL + 1))
        continue
    fi

    # Python instalado
    PYTHON=$(ssh_run $NODE "python3 --version 2>&1")
    check "Python instalado" "$PYTHON" "Python 3"
done

# ==========================================
# Consulta real
# ==========================================

echo ""
echo "--- Versao do Python por node ---"
for NODE in $NODES; do
    VERSION=$(ssh_run $NODE "python3 --version 2>&1")
    if [ -n "$VERSION" ]; then
        HOSTNAME=$(ssh_run $NODE "hostname")
        echo "  $HOSTNAME ($NODE): $VERSION"
    fi
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
