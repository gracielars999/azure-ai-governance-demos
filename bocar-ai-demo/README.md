# Demo Bocar — BIA para manufactura inteligente

Demo en español de gobernanza, seguridad, AI Gateway, Microsoft Foundry y AI FinOps
para una planta automotriz. **Todos los datos operativos son sintéticos.**

## Casos de uso

### Producción y Calidad

- Causa raíz de scrap/retrabajo y costo de no calidad.
- OEE, producción vs. plan, defectos y lotes retenidos.
- Agente sobre una capa analítica sintética.

### Mantenimiento Predictivo

- Señales de MES/historiador simuladas.
- Detección de desviaciones y riesgo de activos.
- Preparación —no ejecución— de una orden ERP con aprobación humana.

### Ingeniería y Cotizaciones

- RFQ desde históricos ficticios en una plataforma analítica.
- Grounding con documentos simulados de PLM y repositorio documental.
- Borrador de precio/margen con citas y aprobación humana.

## Arquitectura

`Usuario → Container App → APIM AI Gateway → Azure AI Foundry (gpt-4o)`

El gateway aplica Managed Identity, límites de tokens por dominio, caché semántica aislada,
Content Safety y telemetría a Application Insights. El Workbook permite chargeback por
dominio y cuantifica el ahorro de caché.

## Estructura

```text
Demo-Bocar/
├─ app/backend/main.py
├─ app/frontend/index.html
├─ knowledge/
│  ├─ agente-instrucciones.md
│  ├─ panel-produccion-calidad.md
│  ├─ panel-mantenimiento-predictivo.md
│  ├─ panel-cotizaciones-ingenieria.md
│  ├─ procedimientos-planta.md
│  └─ fuentes-y-supuestos.md
├─ infra/
│  ├─ apim-policy-core.xml
│  ├─ apim-policy-product-produccion.xml
│  ├─ apim-policy-product-mantenimiento.xml
│  ├─ apim-policy-product-cotizaciones.xml
│  ├─ finops-workbook.json
│  └─ gen-traffic.ps1
└─ guia/guia-sesion.md
```

## Variables de entorno

| Variable | Descripción |
|---|---|
| `APIM_GATEWAY_URL` | URL del APIM, sin `/` final |
| `APIM_API_PATH` | `bocar` |
| `MODEL_DEPLOYMENT` | Despliegue de modelo, por defecto `gpt-4o` |
| `SUBKEY_PRODUCCION` | Suscripción APIM de Producción y Calidad |
| `SUBKEY_MANTENIMIENTO` | Suscripción APIM de Mantenimiento Predictivo |
| `SUBKEY_COTIZACIONES` | Suscripción APIM de Ingeniería y Cotizaciones |
| `SEND_HISTORY` | Mantener en `0` para evitar falsos HITs en caché semántica |

## Ejecutar localmente

```powershell
pip install -r app\backend\requirements.txt
$env:APIM_GATEWAY_URL = "https://<apim>.azure-api.net"
$env:APIM_API_PATH = "bocar"
$env:SUBKEY_PRODUCCION = "<key>"
$env:SUBKEY_MANTENIMIENTO = "<key>"
$env:SUBKEY_COTIZACIONES = "<key>"
python -m uvicorn app.backend.main:app --host 0.0.0.0 --port 8000
```

## Alcance de evidencia

La empresa, procesos generales y presencia industrial se sustentan en fuentes públicas
enumeradas en `knowledge/fuentes-y-supuestos.md`. La evidencia privada usada para diseñar
la versión interna no se publica. Las métricas, costos, activos, RFQ y documentos son
completamente sintéticos.
