# Demo Logística — Agente "Alma" (Asistente Interno de ALMEX)

Aplicación web de chat donde **Alma**, el asistente interno de **ALMEX** (Almacenamiento y Mensajería Express), atiende a **usuarios internos** en dos unidades de negocio gobernadas: **Logística Interna (Management)** con analítica de negocio (revenue, costo, margen, puntualidad e incidencias por cliente) y **Cuentas Corporativas (Operaciones)** con el estado operativo del portafolio (embarques en tránsito, entregas en riesgo, incidencias por sucursal) y rastreo de guías — respondiendo **solo** con base en los paneles y documentación aprobados (knowledge grounding).

Es una de las tres demos de la plataforma compartida. Para desplegar, usa el **[README principal](../README.md)** (botón *Deploy to Azure*, `azd up` o CLI).

## Qué demuestra

- **Gobernanza por unidad de negocio:** dos productos de APIM con cuota distinta — **Logística Interna** (10 000 TPM) y **Cuentas Corporativas** (40 000 TPM) — con **aislamiento de datos**: los datos financieros por cliente son exclusivos de Management.
- **Seguridad keyless:** APIM llama a Azure OpenAI con **Managed Identity**.
- **Caché semántica:** consultas similares se sirven desde Azure Managed Redis (0 tokens).
- **FinOps:** trazas `token-usage` con la dimensión `Solucion=Almex` y `Cache=HIT/MISS` → Workbook `infra/finops-workbook.json`.

## Preguntas que responde

**Logística Interna (Management):**
- ¿Cuál cliente genera más revenue este mes?
- ¿Qué cliente tiene el mejor margen y cuál el peor?
- ¿Qué cliente tiene el peor desempeño de entregas a tiempo?
- ¿Cuál es el costo operativo y el costo por embarque por cliente?

**Cuentas Corporativas (Operaciones):**
- ¿Cuántos embarques tengo en tránsito?
- ¿Cuáles entregas tienen riesgo de retraso?
- ¿Qué sucursal está generando más incidencias?
- ¿Dónde viene mi embarque / cuál es su ETA? (rastreo de guías)

## Estructura

```
almex-ai-demo/
├─ Dockerfile
├─ app/
│  ├─ backend/main.py          # FastAPI: enruta el chat por el AI Gateway
│  └─ frontend/index.html      # UI de chat de Alma
├─ knowledge/                  # guía de embarques + políticas (grounding del prompt)
├─ infra/
│  ├─ apim-policy-core.xml                # caché semántica + MI + backend + trazas
│  ├─ apim-policy-product-clientes.xml     # cuota 10K TPM
│  ├─ apim-policy-product-corporativo.xml  # cuota 40K TPM
│  ├─ finops-workbook.json                 # Workbook por unidad de negocio
│  └─ gen-traffic.ps1                      # generador de tráfico para la demo
└─ (guía compartida en el README principal)
```

## Variables de entorno (Container App)

| Variable | Descripción |
|----------|-------------|
| `APIM_GATEWAY_URL` | URL del gateway de APIM |
| `APIM_API_PATH` | `almex` |
| `MODEL_DEPLOYMENT` | `gpt-4o` |
| `SEND_HISTORY` | `0` (evita falsos HIT de caché al no reenviar todo el historial) |
| `SUBKEY_CLIENTES` / `SUBKEY_CORPORATIVO` | llaves de suscripción por unidad de negocio |

## Generar tráfico para las estadísticas

```powershell
./infra/gen-traffic.ps1 -Base https://<almexAppUrl>
```

Esto lanza consultas variadas (con repeticiones para provocar HIT de caché) que pueblan el Workbook de FinOps: tokens por unidad de negocio, ahorro por caché y latencia.

> Datos ficticios: las guías (`ALM-100234`, `ALM-CORP-77012`, …), rutas y nombres son de ejemplo para el demo.
