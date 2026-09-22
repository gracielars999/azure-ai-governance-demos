# Genera trafico de demo contra la app de Almex (Alma) para poblar el Workbook de FinOps.
# Uso:  ./gen-traffic.ps1 -Base https://<tu-app-almex>.azurecontainerapps.io
param(
  [string]$Base = $env:ALMEX_APP_URL
)
$ErrorActionPreference = "Continue"
if (-not $Base) {
  Write-Error "Indica la URL de la app: ./gen-traffic.ps1 -Base https://<tu-app-almex>.azurecontainerapps.io (o define \$env:ALMEX_APP_URL)"
  exit 1
}
$base = $Base.TrimEnd('/')

function Send-Q($msg, $bu) {
  $body = @{ message = $msg; business_unit = $bu } | ConvertTo-Json
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  try {
    $r = Invoke-RestMethod -Uri "$base/api/chat" -Method Post -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 120
    $t = $r.telemetry
    "{0,-12} {1,-5} tok={2,-5} {3}" -f $bu, $t.cache, $t.total_tokens, $msg.Substring(0,[Math]::Min(48,$msg.Length))
  } catch {
    "{0,-12} ERR  {1}" -f $bu, $_.Exception.Message
  }
}

# (unidad, pregunta, sleepDespues) — las parafrasis van justo despues del original para forzar HIT
# clientes  = Logistica Interna (Management)   | corporativo = Cuentas Corporativas (Operaciones)
$plan = @(
  @("clientes",    "Cual cliente genera mas revenue este mes?",10),
  @("clientes",    "Que cliente factura mas este mes?",10),                     # HIT parafrasis
  @("corporativo", "Cuantos embarques tengo en transito?",30),
  @("corporativo", "Cuantos envios van en camino actualmente?",10),            # HIT parafrasis
  @("clientes",    "Que cliente tiene el mejor margen y cual el peor?",12),
  @("clientes",    "Cual cliente es mas y menos rentable por margen?",10),     # HIT parafrasis
  @("corporativo", "Cuales entregas tienen riesgo de retraso?",30),
  @("corporativo", "Que embarques podrian llegar tarde?",12),                  # HIT parafrasis
  @("clientes",    "Que cliente tiene el peor desempeno de entregas a tiempo?",12),
  @("corporativo", "Que sucursal esta generando mas incidencias?",30),
  @("corporativo", "Cual CEDIS concentra mas problemas?",12),                  # HIT parafrasis
  @("clientes",    "Cual es el costo operativo y el costo por embarque por cliente?",12),
  @("clientes",    "Cual cliente hay que vigilar por bajo desempeno?",12),
  @("corporativo", "Donde viene mi embarque ALM-CORP-77012?",30),
  @("corporativo", "Cual es el ETA de la guia ALM-CORP-77012?",12),           # HIT parafrasis
  @("corporativo", "La guia ALM-CORP-77014 tiene alguna incidencia?",12),
  @("clientes",    "Dame el ranking de clientes por revenue.",10)
)

$i = 0
foreach ($step in $plan) {
  $i++
  Write-Host ("[{0,2}] {1}" -f $i, (Send-Q -msg $step[1] -bu $step[0]))
  Start-Sleep -Seconds $step[2]
}
Write-Host "== TRAFICO COMPLETADO: $i llamadas =="
