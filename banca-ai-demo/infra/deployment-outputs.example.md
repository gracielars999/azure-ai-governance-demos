# Salida del despliegue — Demo Banca AI (Aria)

> Plantilla de referencia. Los valores reales (URLs, llaves, sufijo aleatorio de recursos)
> se generan al desplegar en **tu** suscripción. Tras `azd up` o el botón *Deploy to Azure*,
> los verás como *outputs* del despliegue y en el portal de Azure.
>
> `<sufijo>` = cadena aleatoria que la plantilla agrega a los nombres (p. ej. `ol0k4`).

## 🔗 Accesos rápidos para la demo

| Qué | URL / valor |
|-----|-------------|
| **App web (abrir para el demo)** | `https://ca-banca-web.<region>.azurecontainerapps.io` |
| **AI Gateway (APIM)** | `https://apim-banca-<sufijo>.azure-api.net` |
| **Endpoint del modelo (por el gateway)** | `POST /banca/deployments/gpt-4o/chat/completions?api-version=2024-10-21` |
| **Workbook FinOps** | Portal → `appi-banca-<sufijo>` → Workbooks → *AI FinOps · Banco Contoso* |
| **Agente Foundry** (pilar opcional) | ai.azure.com → proyecto Foundry → agente `Aria-Disputas-Reembolsos` |

## 🔑 Gobernanza por Unidad de Negocio (subscription keys de APIM)

Las llaves se generan al crear las suscripciones de APIM. Recupéralas así (o desde el portal → APIM → Subscriptions):

```bash
az apim subscription show -g <rg> --service-name apim-banca-<sufijo> --sid banca-retail   --query primaryKey -o tsv
az apim subscription show -g <rg> --service-name apim-banca-<sufijo> --sid banca-empresas --query primaryKey -o tsv
```

| Unidad | Producto APIM | Cuota | Subscription key |
|--------|---------------|-------|------------------|
| Banca Retail | `banca-retail` | 10.000 TPM | `<clave-generada-en-el-despliegue>` |
| Banca Empresas | `banca-empresas` | 40.000 TPM | `<clave-generada-en-el-despliegue>` |

## 🧪 Prueba rápida por consola (curl)

```bash
curl -X POST "https://apim-banca-<sufijo>.azure-api.net/banca/deployments/gpt-4o/chat/completions?api-version=2024-10-21" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: <clave-generada-en-el-despliegue>" \
  -d '{"messages":[{"role":"user","content":"Hola"}],"max_tokens":30}'
```

Observa las cabeceras `x-tokens-consumed` / `x-tokens-remaining` (gobernanza) y `x-cache: HIT|MISS` (caché semántica).

## 🧹 Limpieza (al terminar)

```bash
az group delete --name <rg> --yes --no-wait
```
