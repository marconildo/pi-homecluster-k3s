#!/bin/bash
# Flashcard: grava a imagem Debian no SD card e configura o básico.
# Este é o ponto de partida do projeto, roda no seu PC (não nos Pis).
# Configura: IP estático, DNS, APT não-interativo, e injeta chave SSH do root.
#
# Uso:
#   ./flashcard.sh            Modo normal (grava no SD card)
#   ./flashcard.sh --dry-run  Mostra o que seria feito sem executar

set -e

# ==========================================
# Variáveis fixas
# ==========================================

URL="https://raspi.debian.net/tested/20231111_raspi_4_trixie.img.xz"
MOUNT_POINT="/tmp/raspi_root"
DRY_RUN=false

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo ""
    echo "[DRY-RUN] Nenhuma alteracao sera feita"
    echo ""
fi

# ==========================================
# Cleanup em caso de erro
# ==========================================

cleanup() {
    if [ "$DRY_RUN" = false ]; then
        sudo umount $MOUNT_POINT 2>/dev/null || true
        sudo rm -rf $MOUNT_POINT 2>/dev/null || true
    fi
}

trap cleanup EXIT ERR

# ==========================================
# Validar dependências
# ==========================================

for cmd in curl xz dd; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "ERRO: $cmd nao esta instalado"
        exit 1
    fi
done

# ==========================================
# Coletar informações do usuário
# ==========================================

echo ""
read -p "IP do node: " IP
if [ -z "$IP" ]; then
    echo "ERRO: IP e obrigatorio"
    exit 1
fi

read -p "Gateway: " GATEWAY
if [ -z "$GATEWAY" ]; then
    echo "ERRO: Gateway e obrigatorio"
    exit 1
fi

read -p "DNS [8.8.8.8]: " DNS
DNS="${DNS:-8.8.8.8}"

read -p "Device [/dev/sdb]: " DEVICE
DEVICE="${DEVICE:-/dev/sdb}"

read -p "Chave SSH [~/.ssh/id_ed25519.pub]: " SSH_KEY
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519.pub}"

# ==========================================
# Validações
# ==========================================

if [ ! -f "$SSH_KEY" ]; then
    echo "ERRO: Chave SSH nao encontrada em $SSH_KEY"
    exit 1
fi

if [ "$DRY_RUN" = false ] && [ ! -b "$DEVICE" ]; then
    echo "ERRO: $DEVICE nao e um dispositivo de bloco valido"
    exit 1
fi

# ==========================================
# Dry-run: mostra o que seria feito e sai
# ==========================================

if [ "$DRY_RUN" = true ]; then
    echo "==========================================="
    echo "  Arquivos que seriam criados no SD card"
    echo "==========================================="
    echo ""
    echo "--- /etc/network/interfaces.d/eth0 ---"
    echo "auto eth0"
    echo "iface eth0 inet static"
    echo "    address $IP/24"
    echo "    gateway $GATEWAY"
    echo "    dns-nameservers $DNS"
    echo ""
    echo "--- /etc/resolv.conf ---"
    echo "nameserver $DNS"
    echo "nameserver 8.8.4.4"
    echo ""
    echo "--- /etc/apt/apt.conf.d/99noninteractive ---"
    echo "APT::Get::Assume-Yes \"true\";"
    echo "APT::Get::force-yes \"true\";"
    echo "Dpkg::Options { \"--force-confdef\"; \"--force-confold\"; }"
    echo ""
    echo "--- /root/.ssh/authorized_keys ---"
    echo "$(cat $SSH_KEY)"
    echo ""
    echo "==========================================="
    echo "  [DRY-RUN] Nada foi alterado."
    echo "==========================================="
    exit 0
fi

# ==========================================
# Gravar imagem no SD card
# ==========================================

echo ""
echo "Todos os dados em $DEVICE serao APAGADOS!"
echo "Ctrl+C para cancelar, ENTER para continuar..."
read

sudo umount ${DEVICE}* 2>/dev/null || true
curl -L "$URL" | xz -d | sudo dd of=$DEVICE bs=4M status=progress
sync

sleep 3
sudo partprobe $DEVICE 2>/dev/null || true
sleep 2

sudo mkdir -p $MOUNT_POINT
sudo mount ${DEVICE}2 $MOUNT_POINT

# ==========================================
# Configurar rede
# ==========================================

sudo tee $MOUNT_POINT/etc/network/interfaces.d/eth0 > /dev/null <<EOF
auto eth0
iface eth0 inet static
    address $IP/24
    gateway $GATEWAY
    dns-nameservers $DNS
EOF

sudo tee $MOUNT_POINT/etc/resolv.conf > /dev/null <<EOF
nameserver $DNS
nameserver 8.8.4.4
EOF

# ==========================================
# Configurar APT
# ==========================================

sudo tee $MOUNT_POINT/etc/apt/apt.conf.d/99noninteractive > /dev/null <<EOF
APT::Get::Assume-Yes "true";
APT::Get::force-yes "true";
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF

# ==========================================
# Injetar chave SSH
# ==========================================

sudo mkdir -p $MOUNT_POINT/root/.ssh
sudo chmod 700 $MOUNT_POINT/root/.ssh
sudo cp $SSH_KEY $MOUNT_POINT/root/.ssh/authorized_keys
sudo chmod 600 $MOUNT_POINT/root/.ssh/authorized_keys

# ==========================================
# Desabilitar atualizações automáticas do apt
# ==========================================

sudo rm -f $MOUNT_POINT/etc/systemd/system/timers.target.wants/apt-daily.timer
sudo rm -f $MOUNT_POINT/etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer

# ==========================================
# Finalizar
# ==========================================

sudo umount $MOUNT_POINT
sync

echo ""
echo "==========================================="
echo "  Provisionamento concluido"
echo "==========================================="
echo "  IP:        $IP"
echo "  Gateway:   $GATEWAY"
echo "  DNS:       $DNS"
echo "  Device:    $DEVICE"
echo "  Chave SSH: $SSH_KEY"
echo "=========================================="
echo ""
echo "  O cartao pode ser removido com seguranca."
