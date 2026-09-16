#!/usr/bin/env bash
# =============================================================================
#  postdeploy.sh — Construye las imágenes de las apps y las conecta al gateway.
#
#  Úsalo si desplegaste con el botón "Deploy to Azure" con buildAppImages=false,
#  o si quieres reconstruir las imágenes después de cambiar el código.
#
#  Requisitos: Azure CLI (az) con sesión iniciada (az login) y permisos de
#  Contributor sobre el grupo de recursos.
#
#  Uso:
#     ./postdeploy.sh <resource-group> [repo-git-url] [branch]
#
#  Ejemplo:
#     ./postdeploy.sh rg-ai-gov \
#        https://github.com/gracielars999/azure-ai-governance-demos.git main
# =============================================================================
set -euo pipefail

RG="${1:?Uso: ./postdeploy.sh <resource-group> [repo-git-url] [branch]}"
REPO="${2:-https://github.com/gracielars999/azure-ai-governance-demos.git}"
BRANCH="${3:-main}"

echo "==> Buscando el Azure Container Registry en el grupo '$RG'..."
ACR=$(az acr list -g "$RG" --query "[0].name" -o tsv)
ACR_SERVER=$(az acr show -n "$ACR" --query loginServer -o tsv)
echo "    ACR: $ACR ($ACR_SERVER)"

echo "==> Construyendo imagen de Banca (Aria) desde el repo público..."
az acr build --registry "$ACR" --image banca-web:latest "${REPO}#${BRANCH}:banca-ai-demo"

echo "==> Construyendo imagen de Salud (Iris) desde el repo público..."
az acr build --registry "$ACR" --image salud-web:latest "${REPO}#${BRANCH}:salud-ai-demo"

echo "==> Actualizando las Container Apps con las imágenes reales..."
az containerapp update -g "$RG" -n ca-banca-web --image "${ACR_SERVER}/banca-web:latest" -o none
az containerapp update -g "$RG" -n ca-salud-web --image "${ACR_SERVER}/salud-web:latest" -o none

BANCA_URL=$(az containerapp show -g "$RG" -n ca-banca-web --query properties.configuration.ingress.fqdn -o tsv)
SALUD_URL=$(az containerapp show -g "$RG" -n ca-salud-web --query properties.configuration.ingress.fqdn -o tsv)
APIM=$(az apim list -g "$RG" --query "[0].name" -o tsv)

echo ""
echo "============================================================"
echo " Despliegue completo."
echo "   App Banca (Aria):  https://${BANCA_URL}"
echo "   App Salud (Iris):  https://${SALUD_URL}"
echo ""
echo " Llaves de suscripción por unidad de negocio (gobernanza):"
for SID in banca-retail banca-empresas salud-primaria salud-especialidad; do
  KEY=$(az apim subscription show -g "$RG" --service-name "$APIM" --sid "$SID" --query primaryKey -o tsv 2>/dev/null || echo "n/d")
  echo "   ${SID}: ${KEY}"
done
echo "============================================================"
