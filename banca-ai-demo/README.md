# Demo Banca — Agente "Aria" (Disputas y Reembolsos)

Aplicación web de chat donde **Aria**, la asistente de Banco Contoso, ayuda con **disputas de cargos, contracargos y reembolsos** de tarjetas de crédito, respondiendo **solo** con base en las políticas del banco (knowledge grounding).

Es una de las dos demos de la plataforma compartida. Para desplegar, usa el **[README principal](../README.md)** (botón *Deploy to Azure*, `azd up` o CLI).

## Qué demuestra

- **Gobernanza por unidad de negocio:** dos productos de APIM con cuota distinta — **Banca Retail** (10 000 TPM) y **Banca Empresas** (40 000 TPM).
- **Seguridad keyless:** APIM llama a Azure OpenAI con **Managed Identity**.
- **Caché semántica:** preguntas similares en significado se sirven desde Azure Managed Redis (0 tokens, respuesta en ms).
- **FinOps:** trazas `token-usage` con la dimensión `Solucion=Banca` y `Cache=HIT/MISS` → Workbook `infra/finops-workbook.json`.

## Estructura

```
banca-ai-demo/
├─ Dockerfile
├─ app/
│  ├─ backend/main.py          # FastAPI: enruta el chat por el AI Gateway
│  └─ frontend/index.html      # UI de chat de Aria
├─ knowledge/                  # políticas del banco (grounding del prompt)
├─ infra/
│  ├─ apim-policy-core.xml      # caché semántica + MI + backend + trazas FinOps
│  ├─ apim-policy-product-retail.xml     # cuota 10K TPM
│  ├─ apim-policy-product-empresas.xml   # cuota 40K TPM
│  └─ finops-workbook.json      # Workbook de costos/chargeback/caché
└─ guia/guia-sesion.md          # guion para la sesión con el cliente
```

## Variables de entorno (Container App)

| Variable | Descripción |
|----------|-------------|
| `APIM_GATEWAY_URL` | URL del gateway de APIM |
| `APIM_API_PATH` | `banca` |
| `MODEL_DEPLOYMENT` | `gpt-4o` |
| `SUBKEY_RETAIL` / `SUBKEY_EMPRESAS` | llaves de suscripción por unidad de negocio |

## Probar localmente (opcional)

```bash
cd banca-ai-demo
pip install -r app/backend/requirements.txt
export APIM_GATEWAY_URL=https://<apim>.azure-api.net
export APIM_API_PATH=banca
export MODEL_DEPLOYMENT=gpt-4o
export SUBKEY_RETAIL=<llave>
uvicorn app.backend.main:app --port 8000
# abre http://localhost:8000
```

Preguntas de ejemplo para la demo están en [`guia/guia-sesion.md`](guia/guia-sesion.md).
