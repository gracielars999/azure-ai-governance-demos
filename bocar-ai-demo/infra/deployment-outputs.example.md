# Salidas del despliegue — Bocar

> Plantilla sin secretos. No guardes llaves reales en Git.

| Recurso | Valor |
|---|---|
| Container App | `ca-bocar-web` |
| URL | `https://<fqdn>.azurecontainerapps.io` |
| API APIM | `bocar` |
| Producto Producción | `bocar-produccion` |
| Producto Mantenimiento | `bocar-mantenimiento` |
| Producto Cotizaciones | `bocar-cotizaciones` |
| Imagen | `<acr>.azurecr.io/bocar-web:latest` |
| Workbook | `AI FinOps - Bocar Manufactura` |

## Validación esperada

- `GET /healthz` devuelve `{"status":"ok"}`.
- `/api/config` lista los tres dominios gobernados.
- Producción responde sobre scrap/retrabajo sin revelar precios de RFQ.
- Mantenimiento prepara una orden ERP, pero no afirma haberla ejecutado.
- Cotizaciones genera un borrador con fuentes y exige aprobación humana.
- Una paráfrasis repetida produce `x-cache: HIT`.

