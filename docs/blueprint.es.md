# Cluster K3s en ARM – Documento de Arquitectura Técnica

## 1. Objetivo
Definir la arquitectura, premisas operativas y decisiones técnicas para el despliegue de un cluster Kubernetes ligero basado en K3s en hardware ARM.

Este documento describe decisiones técnicas, justificaciones, riesgos y limitaciones.

## 2. Alcance

### Incluido:
- Cluster K3s en hardware ARM
- Automatización vía Ansible
- Hardening básico del sistema
- Red IPv4
- Instalación no interactiva

### No incluido:
- Alta disponibilidad multi-datacenter
- Respaldo automatizado de etcd
- Observabilidad empresarial (Prometheus/Grafana)
- Gestión de secretos empresarial
- Cumplimiento normativo (GDPR, ISO, etc.)

## 3. Premisas
- Entorno solo IPv4
- Red local confiable
- Sin requisito de HA distribuida
- Uso educativo, laboratorio o staging ligero
- Operación por equipo técnico con acceso SSH vía clave

## 4. Arquitectura

### 4.1 Hardware
- **Plataforma:** Raspberry Pi 4

#### Criterios:
- ARMv8 64-bit
- Hasta 8GB RAM
- Gigabit Ethernet real
- Bajo consumo energético

#### Riesgo:
- No es hardware con ECC
- Sin SLA del fabricante
- El almacenamiento vía SD puede degradarse

#### Mitigación:
- Uso de SD de alta calidad
- Respaldo periódico
- Reprovisionamiento automatizado

### 4.2 Sistema Operativo
- **Base:** Debian Trixie (testing) para ARM.

#### Motivación:
- Kernel reciente
- Mejor soporte ARM
- Base mínima

#### Riesgo:
- Testing tiene mayor frecuencia de actualización
- Menor previsibilidad comparado con Stable

#### Alternativa soportada:
- Debian Stable

### 4.3 Distribución Kubernetes
- **Distribución:** K3s

#### Criterios:
- Menor footprint
- Instalación simplificada
- Compatible con ARM
- Single binary
- SQLite estándar en single-node
- etcd embebido opcional en HA

#### Trade-off:
- Menos modular que kubeadm
- Mayor abstracción sobre componentes internos

#### Justificación:
Para hardware limitado, kubeadm añade sobrecarga operativa y de recursos.

## 5. Decisiones del Sistema

### 5.1 Swap
- **Estado:** Deshabilitado.

#### Motivación:
- Adherencia a las recomendaciones oficiales de Kubernetes
- Previsibilidad de gestión de memoria

#### Riesgo:
- Sobrecarga puede generar OOMKill

#### Mitigación:
- Dimensionamiento adecuado de pods
- Límites explícitos de memoria

### 5.2 cgroups
- **Estado:** Habilitado explícitamente.

#### Motivación:
- Garantizar cumplimiento de límites de memoria
- Compatibilidad consistente entre nodos

### 5.3 IPv6
- **Estado:** Deshabilitado.

#### Motivación:
- Entorno exclusivamente IPv4
- Reducción de complejidad operativa

#### Limitación:
- No soporta dual-stack
- No adecuado para entornos que requieren IPv6

### 5.4 WiFi
- **Estado:** Deshabilitado.

#### Motivación:
- Evitar múltiples rutas
- Garantizar tráfico exclusivo vía Ethernet
- Mantener previsibilidad de IP

## 6. Red

### 6.1 IP Estática
Todos los nodos tienen IP estática.

#### Motivación:
- Evitar rotura de endpoints
- Estabilidad de certificados
- Previsibilidad de acceso

#### Riesgo:
- Cambio manual necesario si la red cambia

### 6.2 DNS
- **Estándar:** 8.8.8.8 / 8.8.4.4 (Google)
- Configurable para entornos corporativos.

#### Limitación:
- Puede ser bloqueado en redes empresariales

## 7. Automatización
- **Herramienta:** Ansible

### Principios:
- Ejecución idempotente
- Totalmente no interactivo
- Fail-fast
- Separación clara de fases

### Estructura:
- **Bootstrap:**
  - Uso de raw hasta la instalación de Python
  - `gather_facts: false` inicialmente
- **APT:**
  - Modo no interactivo
  - Timers automáticos deshabilitados
  - Prevención de bloqueo concurrente

## 8. Seguridad

### Modelo de Acceso

| Etapa | Acceso SSH |
| :--- | :--- |
| Inicial | root vía clave |
| Post-configuración | usuario k3s vía clave |
| Final | root SSH desabilitado |

### Controles:
- Sin contraseña
- Solo autenticación por clave
- Sudo NOPASSWD para automatización
- SSH root deshabilitado tras provisionamiento

### Limitación:
- No implementa MFA
- No se integra con IAM externo
- No tiene RBAC personalizado más allá del estándar K3s

## 9. Validación

Validación independiente vía scripts shell:
- Verificación de swap
- Verificación de cgroups
- Estado del cluster
- Estado de los nodos
- Retorno vía código 0/1 para integración con pipelines.

## 10. Riesgos Conocidos
- Fallo de tarjeta SD
- Corrupción por apagado abrupto
- Falta de HA si hay un solo control plane
- Sin respaldo automatizado de datastore
- Actualizaciones de Debian testing pueden introducir cambios inesperados

## 11. No-Objetivos
Este proyecto no pretende:
- Reemplazar entorno Kubernetes corporativo
- Ofrecer SLA
- Cumplir requisitos regulatorios
- Proveer cluster multi-región

## 12. Principios Arquitectónicos
> Simplicidad > Complejidad
>
> Automatización > Operación manual
>
> Previsibilidad > Flexibilidad
>
> Consistencia entre nodos
>
> Reprovisionamiento rápido en lugar de troubleshooting prolongado
