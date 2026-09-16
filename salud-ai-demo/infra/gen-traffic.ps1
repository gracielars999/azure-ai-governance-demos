# Genera trafico de demo contra la app de Salud (Iris) para poblar el Workbook de FinOps.
# Uso:  ./gen-traffic.ps1 -Base https://<tu-app-salud>.azurecontainerapps.io
param(
  [string]$Base = $env:SALUD_APP_URL
)
$ErrorActionPreference = "Continue"
if (-not $Base) {
  Write-Error "Indica la URL de la app: ./gen-traffic.ps1 -Base https://<tu-app-salud>.azurecontainerapps.io (o define \$env:SALUD_APP_URL)"
  exit 1
}
$base = $Base.TrimEnd('/')

function Send-Q($msg, $bu) {
  $body = @{ message = $msg; business_unit = $bu } | ConvertTo-Json
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  try {
    $r = Invoke-RestMethod -Uri "$base/api/chat" -Method Post -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 120
    $t = $r.telemetry
    "{0,-13} {1,-5} tok={2,-5} {3}" -f $bu, $t.cache, $t.total_tokens, $msg.Substring(0,[Math]::Min(48,$msg.Length))
  } catch {
    "{0,-13} ERR  {1}" -f $bu, $_.Exception.Message
  }
}

# (division, pregunta, sleepDespues) — paráfrasis van justo despues del original para forzar HIT
$plan = @(
  @("especialidad","Cual es la dosis inicial de Cardioxel para hipertension?",10),
  @("especialidad","Que dosis inicial se recomienda de Cardioxel?",10),                 # HIT paráfrasis
  @("primaria",    "Para que esta indicado Gastrisan?",30),
  @("especialidad","Cuales son las contraindicaciones de Cardioxel?",10),
  @("especialidad","En que casos no se debe usar Cardioxel?",10),                        # HIT paráfrasis
  @("especialidad","Que reacciones adversas tiene Cardioxel?",12),
  @("primaria",    "Como reporto una reaccion adversa de un medicamento?",30),
  @("especialidad","Como se dosifica Gastrisan en reflujo?",10),
  @("especialidad","Cual es la posologia de Gastrisan para el reflujo?",12),             # HIT paráfrasis
  @("especialidad","Cual es el mecanismo de accion de Gastrisan?",12),
  @("primaria",    "Cardioxel se puede usar durante el embarazo?",30),
  @("especialidad","Que interacciones farmacologicas tiene Cardioxel?",12),
  @("especialidad","Cual es la dosis maxima diaria de Cardioxel?",10),
  @("especialidad","Hasta que dosis diaria se puede subir Cardioxel?",12),              # HIT paráfrasis
  @("primaria",    "Que presentaciones tiene Gastrisan?",30),
  @("especialidad","Que estudios respaldan la eficacia de Cardioxel?",12),
  @("especialidad","Como debo almacenar Gastrisan?",10)
)

$i = 0
foreach ($step in $plan) {
  $i++
  Write-Host ("[{0,2}] {1}" -f $i, (Send-Q -msg $step[1] -bu $step[0]))
  Start-Sleep -Seconds $step[2]
}
Write-Host "== TRAFICO COMPLETADO: $i llamadas =="
