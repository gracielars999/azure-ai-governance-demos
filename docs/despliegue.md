# Guía de despliegue detallada

Esta guía explica, paso a paso, cómo desplegar las **cuatro demos de IA gobernada** (Banca + Salud + Logística + Manufactura) sobre una plataforma compartida en tu propio tenant de Azure.

---

## 1. Requisitos previos

- Una **suscripción de Azure** con permisos de **Owner** o **Contributor + User Access Administrator** en el grupo de recursos (se crean *role assignments*).
- **Cuota de Azure OpenAI** en la región elegida para: `gpt-4o` (GlobalStandard) y `text-embedding-3-small` (Standard). Revisa en *Foundry → Quotas*.
- Herramientas (solo para las opciones B y C):
  - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) `az login`
  - [Azure Developer CLI](https://aka.ms/azd) (opción B)
- Región sugerida: **East US 2** (buena disponibilidad de los SKUs usados).

> El módulo **RediSearch** de Azure Managed Redis **solo se puede habilitar al crear** la caché — el Bicep ya lo hace.

---

## 2. Opción A — Botón "Deploy to Azure"

1. Haz clic en el botón del [README principal](../README.md#-desplegar-en-tu-propio-tenant).
2. En el portal, elige **Suscripción**, **Grupo de recursos** (nuevo) y **Región**.
3. Parámetros relevantes:
   | Parámetro | Valor sugerido |
   |-----------|----------------|
   | `apimPublisherEmail` | tu correo |
   | `buildAppImages` | `true` (construye y conecta las apps automáticamente) |
   | `deploySemanticCache` | `true` |
   | `chatCapacity` | `20` (bájalo si tienes poca cuota) |
4. **Revisar + crear**. El despliegue tarda **~35–45 min**.
5. Al terminar, ve a *Outputs* para obtener `bancaAppUrl`, `saludAppUrl`, `almexAppUrl` y `bocarAppUrl`.

> Si `buildAppImages` quedó en `false`, corre `scripts/postdeploy.sh <rg>` (o `.ps1`) una vez para construir las imágenes y conectarlas.

---

## 3. Opción B — `azd up`

```bash
git clone https://github.com/gracielars999/azure-ai-governance-demos.git
cd azure-ai-governance-demos
azd auth login
azd up
```

`azd` te pedirá entorno, suscripción y región; luego provisiona la infraestructura y **construye + despliega** las cuatro apps. Las URLs quedan en la salida de `azd up`.

Para eliminar todo: `azd down --purge`.

---

## 4. Opción C — Azure CLI (control total)

```bash
az login
az group create -n rg-ai-gov -l eastus2

az deployment group create -g rg-ai-gov \
  --template-file infra/main.bicep \
  --parameters apimPublisherEmail=tu-correo@empresa.com \
               buildAppImages=false

# Construir imágenes desde el repo público y conectar las apps + ver llaves:
./scripts/postdeploy.sh rg-ai-gov
# (en Windows) ./scripts/postdeploy.ps1 -ResourceGroup rg-ai-gov
```

---

## 5. Verificar la demo

1. **Apps arriba:** abre `bancaAppUrl`, `saludAppUrl`, `almexAppUrl` y `bocarAppUrl`. Deberías ver el chat de Aria / Iris / Alma / BIA.
2. **Prueba de gobernanza:** en la app, haz varias preguntas seguidas para acercarte al límite de TPM del producto; verás el aviso 429 controlado.
3. **Prueba de caché semántica:** repite una pregunta con otras palabras pero igual significado; la segunda debería responder más rápido (HIT) — revísalo en el Workbook.

---

## 6. Importar el Workbook de FinOps

1. Portal → **Azure Monitor → Workbooks → Nuevo**.
2. Botón **</> Editor avanzado** → pega el contenido de `banca-ai-demo/infra/finops-workbook.json` → **Aplicar**.
3. **Guardar** apuntando el recurso al **Application Insights** desplegado (`aigov-appi-*`).
4. Repite con `salud-ai-demo/infra/finops-workbook.json` y `almex-ai-demo/infra/finops-workbook.json`.

El Workbook muestra: tokens por unidad de negocio/división, costo y **chargeback** (USD/MXN), **ahorro por caché semántica** y latencia. Cada Workbook filtra por su `Solucion` (`Banca` / `Salud` / `Almex`).

---

## 7. Generar tráfico de demostración

```powershell
./salud-ai-demo/infra/gen-traffic.ps1 -Base https://<saludAppUrl>
./almex-ai-demo/infra/gen-traffic.ps1 -Base https://<almexAppUrl>
./bocar-ai-demo/infra/gen-traffic.ps1 -Base https://<bocarAppUrl>
```

Genera consultas variadas con repeticiones (para provocar HIT de caché) y así poblar las estadísticas. Puedes hacer lo mismo manualmente desde la app de banca.

---

## 8. (Opcional) Pilar Foundry IQ / Knowledge base

En `scripts/foundry-agent/` hay utilidades para crear un **agente de Foundry con knowledge base** (Foundry IQ) y validarlo, por si quieres mostrar ese pilar además del grounding por prompt de las apps. Requiere variables como `PROJECT_ENDPOINT` y `KNOWLEDGE_DIR`. Consulta los comentarios de `setup_agent.py`.

---

## 9. Solución de problemas

| Síntoma | Causa probable | Acción |
|---------|----------------|--------|
| La app muestra error 500 al chatear | imágenes aún no construidas (placeholder) | corre `scripts/postdeploy.sh <rg>` |
| 401/403 de APIM a Foundry | el *role assignment* de Managed Identity tarda en propagar | espera 5–10 min y reintenta |
| Falla el despliegue del modelo | cuota insuficiente | baja `chatCapacity` / cambia de región |
| No hay HIT de caché | umbral muy bajo o historial reenviado | verifica `SEND_HISTORY=0` (salud/almex) y el `score-threshold` en `apim-policy-core.xml` |
| El Workbook sale vacío | sin tráfico o App Insights equivocado | genera tráfico y confirma el recurso del Workbook |

---

## 10. Limpieza

```bash
az group delete -n rg-ai-gov --yes --no-wait
# o, si usaste azd:
azd down --purge
```

> API Management en SKU Developer y Azure Managed Redis generan costo mientras estén encendidos. **Apaga la demo** cuando termines.
