# Demo Salud — Agente "Iris" (Visitadores Médicos)

Aplicación web de chat donde **Iris**, la asistente de Laboratorios Contoso, brinda a los **visitadores médicos** información de **productos farmacéuticos** (vademécum, políticas de promoción y farmacovigilancia), respondiendo **solo** con base en la documentación aprobada (knowledge grounding).

Es una de las dos demos de la plataforma compartida. Para desplegar, usa el **[README principal](../README.md)** (botón *Deploy to Azure*, `azd up` o CLI).

## Qué demuestra

- **Gobernanza por división comercial:** dos productos de APIM con cuota distinta — **Atención Primaria** (10 000 TPM) y **Especialidad** (40 000 TPM).
- **Seguridad keyless:** APIM llama a Azure OpenAI con **Managed Identity**.
- **Caché semántica:** consultas similares se sirven desde Azure Managed Redis (0 tokens).
- **FinOps:** trazas `token-usage` con la dimensión `Solucion=Salud` y `Cache=HIT/MISS` → Workbook `infra/finops-workbook.json`.

## Estructura

```
salud-ai-demo/
├─ Dockerfile
├─ app/
│  ├─ backend/main.py          # FastAPI: enruta el chat por el AI Gateway
│  └─ frontend/index.html      # UI de chat de Iris
├─ knowledge/                  # vademécum + políticas (grounding del prompt)
├─ infra/
│  ├─ apim-policy-core.xml               # caché semántica + MI + backend + trazas
│  ├─ apim-policy-product-primaria.xml    # cuota 10K TPM
│  ├─ apim-policy-product-especialidad.xml# cuota 40K TPM
│  ├─ finops-workbook.json                # Workbook por división
│  └─ gen-traffic.ps1                     # generador de tráfico para la demo
└─ (guía compartida en el README principal)
```

## Variables de entorno (Container App)

| Variable | Descripción |
|----------|-------------|
| `APIM_GATEWAY_URL` | URL del gateway de APIM |
| `APIM_API_PATH` | `salud` |
| `MODEL_DEPLOYMENT` | `gpt-4o` |
| `SEND_HISTORY` | `0` (evita falsos HIT de caché al no reenviar todo el historial) |
| `SUBKEY_PRIMARIA` / `SUBKEY_ESPECIALIDAD` | llaves de suscripción por división |

## Generar tráfico para las estadísticas

```powershell
./infra/gen-traffic.ps1 -Base https://<saludAppUrl>
```

Esto lanza consultas variadas (con repeticiones para provocar HIT de caché) que pueblan el Workbook de FinOps: tokens por división, ahorro por caché y latencia.
