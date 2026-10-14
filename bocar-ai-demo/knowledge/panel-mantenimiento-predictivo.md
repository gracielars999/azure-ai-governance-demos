# Panel sintético — Mantenimiento Predictivo

> Escenario ficticio para demostración. Corte: **14-oct-2026, turno 1**.

## Calidad por línea

| Línea | Scrap | Tasa | Defecto principal | Piezas por defecto principal |
|---|---:|---:|---|---:|
| SPM-04 | 145 | 5.9% | Porosidad | 68 |
| HPDC-01 | 121 | 2.8% | Porosidad | 54 |
| INJ-03 | 88 | 1.5% | Marca de flujo | 37 |
| HPDC-02 | 84 | 2.1% | Rebaba | 33 |

**Scrap total:** 438 piezas (2.63%).  
**Defecto dominante de planta:** porosidad, 122 piezas (27.9% del scrap).

## Lotes retenidos

| Lote | Línea | Cantidad | Motivo | Estatus | Siguiente paso |
|---|---|---:|---|---|---|
| BCR-241014-A17 | SPM-04 | 320 | Porosidad en rayos X arriba del límite | Retenido | Muestreo ampliado y revisión de parámetros |
| BCR-241014-H08 | HPDC-01 | 180 | Variación dimensional en alojamiento | En inspección | CMM al 100% de muestra |
| BCR-241014-P31 | INJ-03 | 240 | Marca de flujo cosmética | Liberación condicionada | Validación visual con Calidad |

Los clientes se mantienen anonimizados como **OEM-A**, **OEM-B** y **OEM-C**.

## Riesgo predictivo de activos (próximas 24 horas)

| Activo | Línea | Riesgo | Señales | Ventana | Acción recomendada |
|---|---|---:|---|---|---|
| SPM04-HYD-P01 | SPM-04 | 82% | Presión -11%, vibración +31%, temperatura +14 °C | 0–8 h | Inspección P1 en la pausa más próxima |
| HPDC01-FUR-TC07 | HPDC-01 | 67% | Deriva +18 °C, 3 alarmas intermitentes | 0–12 h | Verificar termopar y calibración |
| INJ03-SCR-M02 | INJ-03 | 46% | Torque +9%, ciclo +4% | 12–24 h | Inspección P2 y tendencia |
| HPDC02-CLW-P03 | HPDC-02 | 28% | Caudal -4%, estable | >24 h | Monitoreo, sin intervención inmediata |

El riesgo es una señal de priorización, **no una confirmación de falla**.

## Órdenes de trabajo

| Orden | Prioridad | Activo | Trabajo | Estado | Compromiso |
|---|---|---|---|---|---|
| OT-10482 | P1 | SPM04-HYD-P01 | Inspección de bomba y circuito hidráulico | Abierta, vencida 2.3 h | Inmediato |
| OT-10490 | P2 | HPDC01-FUR-TC07 | Verificación y calibración de termopar | Planeada | Antes de 18:00 |
| OT-10494 | P2 | INJ03-SCR-M02 | Revisión de tornillo y torque | Planeada | 18-oct-2026 |
| OT-10479 | P3 | HPDC02-CLW-P03 | Limpieza de filtro de enfriamiento | En ejecución | 14-oct-2026 15:30 |

## Diagnóstico probable de SPM-04

- Coinciden baja presión hidráulica, inestabilidad térmica, mayor porosidad y mayor scrap.
- Hipótesis prioritaria: la variación de presión/temperatura está afectando el llenado y
  solidificación. **No es una causa raíz confirmada**.
- Validación: ejecutar OT-10482, verificar parámetros dentro del rango aprobado y evaluar
  una muestra de arranque antes de liberar producción.
