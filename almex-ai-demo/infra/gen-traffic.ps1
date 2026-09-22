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
$plan = @(
  @("clientes",    "Donde viene mi embarque ALM-100234?",10),
  @("clientes",    "En que parte del trayecto va mi guia ALM-100234?",10),      # HIT parafrasis
  @("corporativo", "Cual es el ETA de la guia ALM-CORP-77012?",30),
  @("clientes",    "Cual es la fecha estimada de llegada de ALM-100239?",10),
  @("clientes",    "Cuando llega aproximadamente mi paquete ALM-100239?",10),   # HIT parafrasis
  @("clientes",    "Hubo alguna incidencia con mi envio ALM-100236?",12),
  @("clientes",    "Mi guia ALM-100236 tuvo algun problema?",10),               # HIT parafrasis
  @("clientes",    "Puedo cambiar la direccion de entrega de ALM-100234?",30),
  @("clientes",    "Se puede modificar el domicilio de entrega de ALM-100234?",12), # HIT parafrasis
  @("clientes",    "Mi paquete ALM-100237 va a llegar tarde?",12),
  @("corporativo", "Estatus del embarque corporativo ALM-CORP-77013?",30),
  @("corporativo", "Como va la ruta de ALM-CORP-77013?",12),                    # HIT parafrasis
  @("clientes",    "Ya entregaron mi paquete ALM-100238?",10),
  @("clientes",    "Mi paquete llego danado, que hago?",30),
  @("corporativo", "La guia ALM-CORP-77014 tiene alguna incidencia?",12),
  @("clientes",    "No tengo mi numero de guia, me puedes ayudar?",12),
  @("clientes",    "Puedo reprogramar la entrega de ALM-100235?",10)
)

$i = 0
foreach ($step in $plan) {
  $i++
  Write-Host ("[{0,2}] {1}" -f $i, (Send-Q -msg $step[1] -bu $step[0]))
  Start-Sleep -Seconds $step[2]
}
Write-Host "== TRAFICO COMPLETADO: $i llamadas =="
