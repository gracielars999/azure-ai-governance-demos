# Salida del despliegue — Demo Salud AI (Iris)

> Plantilla de referencia. Los valores reales (URLs, llaves, sufijo aleatorio de recursos)
> se generan al desplegar en **tu** suscripción. Tras `azd up` o el botón *Deploy to Azure*,
> los verás como *outputs* del despliegue y en el portal de Azure.
>
> **Arquitectura compartida:** la demo de salud reutiliza la misma plataforma que la de banca
> (APIM, Foundry, Redis, App Insights, entorno de Container Apps). El despliegue por defecto de
> este repo crea **ambas** demos sobre una sola plataforma: una API `banca` y una API `salud` en
> el mismo AI Gateway, cada una con sus propias cuotas y caché aislada por suscripción.

## 🔗 Accesos rápidos para la demo

| Qué | URL / valor |
|-----|-------------|
| **App web (abrir para el demo)** | `https://ca-salud-web.<region>.azurecontainerapps.io` |
| **AI Gateway (APIM)** | `https://apim-banca-<sufijo>.azure-api.net` |
| **Endpoint del modelo (por el gateway)** | `POST /salud/deployments/gpt-4o/chat/completions?api-version=2024-10-21` |
| **Workbook FinOps (Salud)** | Portal → `appi-banca-<sufijo>` → Workbooks → *AI FinOps · Laboratorios Contoso (Salud)* (filtra por `Solucion == "Salud"`) |

## 🔑 Gobernanza por División / Línea (subscription keys de APIM)

```bash
az apim subscription show -g <rg> --service-name apim-banca-<sufijo> --sid salud-primaria     --query primaryKey -o tsv
az apim subscription show -g <rg> --service-name apim-banca-<sufijo> --sid salud-especialidad --query primaryKey -o tsv
```

| División | Producto APIM | Cuota | Subscription key |
|--------|---------------|-------|------------------|
| Atención Primaria | `salud-primaria` | 10.000 TPM | `<clave-generada-en-el-despliegue>` |
| Especialidad | `salud-especialidad` | 40.000 TPM | `<clave-generada-en-el-despliegue>` |

## 🧪 Prueba rápida por consola (curl)

```bash
curl -X POST "https://apim-banca-<sufijo>.azure-api.net/salud/deployments/gpt-4o/chat/completions?api-version=2024-10-21" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: <clave-generada-en-el-despliegue>" \
  -d '{"messages":[{"role":"user","content":"¿Dosis inicial de Cardioxel?"}],"max_tokens":60}'
```

## 📊 Generar tráfico para el Workbook

```powershell
./infra/gen-traffic.ps1 -Base https://ca-salud-web.<region>.azurecontainerapps.io
```

## 🐛 Nota — comportamiento de caché / conversación

- **Caché semántica:** `score-threshold = 0.2` (guía de Microsoft: valores > 0.2 pueden provocar HIT erróneos). Con 0.2, una **paráfrasis** → HIT (ahorro); una pregunta de **otro tema** → MISS.
- **Historial:** por defecto la app **NO reenvía** historial al gateway (`SEND_HISTORY=0`); así se evita que el hilo completo colapse en la primera respuesta cacheada. Para memoria conversacional usa `SEND_HISTORY=1`.

## 🧹 Limpieza (al terminar)

```bash
az group delete --name <rg> --yes --no-wait
```
