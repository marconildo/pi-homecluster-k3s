# Netdata nos Raspberry Pi 4B — Setup completo

## Pré-requisitos

- Debian instalado
- `curl` disponível
- Bot do Telegram criado via `@BotFather` com token e chat_id em mãos
- Mensagem `/start` enviada pro bot antes de qualquer teste

---

## 1. Instalar Netdata

```bash
curl -sSL https://my-netdata.io/kickstart.sh -o /tmp/kickstart.sh
sudo bash /tmp/kickstart.sh --dont-start-it
```

## 2. Instalar lm-sensors

```bash
sudo apt install lm-sensors -y
```

## 3. Configurar /etc/netdata/netdata.conf

```bash
sudo nano /etc/netdata/netdata.conf
```

Adiciona no final do arquivo:

```ini
[global]
    update every = 5

[db]
    mode = ram
    retention = 3600

[web]
    bind to = 127.0.0.1
```

## 4. Configurar notificações Telegram

```bash
sudo cp /usr/lib/netdata/conf.d/health_alarm_notify.conf /etc/netdata/
sudo nano /etc/netdata/health_alarm_notify.conf
```

Localiza e ajusta as três linhas:

```ini
SEND_TELEGRAM="YES"
TELEGRAM_BOT_TOKEN="SEU_TOKEN_AQUI"
DEFAULT_RECIPIENT_TELEGRAM="SEU_CHAT_ID_AQUI"
```

## 5. Criar alerta de temperatura

```bash
sudo tee /etc/netdata/health.d/temperature.conf << 'EOF'
alarm: rpi_temperature
   on: sensors.temperature_cpu_thermal-virtual-0_temp1_input
 lookup: max -5s of input
  units: Celsius
  every: 30s
   warn: $this > 50
   crit: $this > 70
summary: Raspberry Pi temperature
   info: CPU temperature
     to: sysadmin
EOF
```

## 6. Iniciar e habilitar no boot

```bash
sudo systemctl enable --now netdata
```

## 7. Testar notificação Telegram

```bash
sudo -u netdata /usr/libexec/netdata/plugins.d/alarm-notify.sh test telegram
```

Deve chegar mensagem de teste no Telegram.

---

## Alertas ativos

| métrica | warning | critical | delay |
|---|---|---|---|
| CPU | 75% | 85% | 10 minutos contínuos |
| RAM | 80% | 90% | imediato |
| Disco | 80% | 95% | imediato |
| Temperatura | 50°C | 70°C | imediato |

---

## Observações

- `mode = ram` — sem escrita em disco, ideal para cartão SD
- `retention = 3600` — histórico de 1 hora em RAM
- `bind to = 127.0.0.1` — dashboard não exposto na rede
- Alerta de CPU usa média de 10 minutos — evita falsos positivos por picos curtos
- Alerta de temperatura é imediato assim que passa do threshold
- Configuração idêntica nos três nós — só o hostname muda, automaticamente
