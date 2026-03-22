#!/bin/bash

WORKERS=("192.168.18.242" "192.168.18.244")
MASTER="192.168.18.240"
USER="k3s"

echo "Iniciando desligamento gracefully..."

# 1. Encerra os agentes k3s dos Wokers
for node in "${WORKERS[@]}"; do
  echo "Parando k3s-agent em $node..."
  ssh $USER@$node "sudo systemctl stop k3s-agent && sync"
done

# 2. Encerra o k3s do Control Plane
echo "Parando k3s server em $MASTER..."
ssh $USER@$MASTER "sudo systemctl stop k3s && sync"

# 3. Desliga as PIs
for node in "${WORKERS[@]}" "$MASTER"; do
    echo "Desligando $node..."
    ssh $USER@$node "sudo shutdown -h now"
done