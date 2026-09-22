<#
.SYNOPSIS
    postdeploy.ps1 — Construye las imágenes de las apps y las conecta al gateway.

.DESCRIPTION
    Úsalo si desplegaste con el botón "Deploy to Azure" con buildAppImages=false,
    o si quieres reconstruir las imágenes después de cambiar el código.
    Requiere Azure CLI (az) con sesión iniciada (az login) y Contributor sobre el RG.

.EXAMPLE
    ./postdeploy.ps1 -ResourceGroup rg-ai-gov
#>
param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$RepoGitUrl = "https://github.com/gracielars999/azure-ai-governance-demos.git",
    [string]$Branch = "main"
)
$ErrorActionPreference = "Stop"

Write-Host "==> Buscando el Azure Container Registry en el grupo '$ResourceGroup'..."
$acr = az acr list -g $ResourceGroup --query "[0].name" -o tsv
$acrServer = az acr show -n $acr --query loginServer -o tsv
Write-Host "    ACR: $acr ($acrServer)"

Write-Host "==> Construyendo imagen de Banca (Aria)..."
az acr build --registry $acr --image banca-web:latest "$RepoGitUrl#${Branch}:banca-ai-demo"

Write-Host "==> Construyendo imagen de Salud (Iris)..."
az acr build --registry $acr --image salud-web:latest "$RepoGitUrl#${Branch}:salud-ai-demo"

Write-Host "==> Construyendo imagen de Logística (Alma)..."
az acr build --registry $acr --image almex-web:latest "$RepoGitUrl#${Branch}:almex-ai-demo"

Write-Host "==> Actualizando las Container Apps con las imágenes reales..."
az containerapp update -g $ResourceGroup -n ca-banca-web --image "$acrServer/banca-web:latest" -o none
az containerapp update -g $ResourceGroup -n ca-salud-web --image "$acrServer/salud-web:latest" -o none
az containerapp update -g $ResourceGroup -n ca-almex-web --image "$acrServer/almex-web:latest" -o none

$bancaUrl = az containerapp show -g $ResourceGroup -n ca-banca-web --query properties.configuration.ingress.fqdn -o tsv
$saludUrl = az containerapp show -g $ResourceGroup -n ca-salud-web --query properties.configuration.ingress.fqdn -o tsv
$almexUrl = az containerapp show -g $ResourceGroup -n ca-almex-web --query properties.configuration.ingress.fqdn -o tsv
$apim = az apim list -g $ResourceGroup --query "[0].name" -o tsv

Write-Host ""
Write-Host "============================================================"
Write-Host " Despliegue completo."
Write-Host "   App Banca (Aria):       https://$bancaUrl"
Write-Host "   App Salud (Iris):       https://$saludUrl"
Write-Host "   App Logística (Alma):   https://$almexUrl"
Write-Host ""
Write-Host " Llaves de suscripción por unidad de negocio (gobernanza):"
foreach ($sid in @("banca-retail","banca-empresas","salud-primaria","salud-especialidad","almex-clientes","almex-corporativo")) {
    $key = az apim subscription show -g $ResourceGroup --service-name $apim --sid $sid --query primaryKey -o tsv 2>$null
    if (-not $key) { $key = "n/d" }
    Write-Host "   ${sid}: $key"
}
Write-Host "============================================================"
