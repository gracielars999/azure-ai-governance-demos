param(
  [string]$Base = $env:BOCAR_APP_URL
)

$ErrorActionPreference = "Continue"
if (-not $Base) {
  Write-Error "Indica -Base https://<app>.azurecontainerapps.io o define BOCAR_APP_URL."
  exit 1
}
$base = $Base.TrimEnd("/")

function Send-Question($Message, $BusinessUnit) {
  $payload = @{ message = $Message; business_unit = $BusinessUnit } | ConvertTo-Json
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
  try {
    $result = Invoke-RestMethod -Uri "$base/api/chat" -Method Post -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 120
    $telemetry = $result.telemetry
    "{0,-12} {1,-5} tok={2,-5} {3}" -f $BusinessUnit, $telemetry.cache, $telemetry.total_tokens, $Message.Substring(0, [Math]::Min(54, $Message.Length))
  } catch {
    "{0,-12} ERROR {1}" -f $BusinessUnit, $_.Exception.Message
  }
}

$plan = @(
  @("produccion", "Cual es la principal causa probable de scrap y retrabajo?", 8),
  @("produccion", "Que esta provocando el costo de no calidad?", 8),
  @("produccion", "Cuanto cuesta la no calidad en este turno?", 8),
  @("produccion", "Como esta el OEE y que linea requiere atencion?", 8),
  @("mantenimiento", "Que activos tienen mayor riesgo de falla en las proximas 24 horas?", 8),
  @("mantenimiento", "Que maquina tiene el riesgo predictivo mas alto?", 8),
  @("mantenimiento", "Que ordenes de mantenimiento son criticas?", 8),
  @("mantenimiento", "Prepara una propuesta de orden ERP para el activo de mayor riesgo.", 8),
  @("cotizaciones", "Genera un borrador para el RFQ-26-184 con fuentes.", 8),
  @("cotizaciones", "Cual es el precio sugerido del RFQ-26-184?", 8),
  @("cotizaciones", "Que historicos son comparables con este RFQ?", 8),
  @("cotizaciones", "Que validaciones faltan antes de enviar la oferta?", 8),
  @("produccion", "Cual es el estatus del lote BCR-241014-A17?", 8),
  @("mantenimiento", "Que debo hacer ante una alarma de temperatura de molde?", 8)
)

$index = 0
foreach ($step in $plan) {
  $index++
  Write-Host ("[{0,2}] {1}" -f $index, (Send-Question -Message $step[1] -BusinessUnit $step[0]))
  Start-Sleep -Seconds $step[2]
}
Write-Host "Trafico completado: $index llamadas."

