# Panel sintético — Producción y Calidad

> Escenario ficticio para demostración. Corte: **14-oct-2026, turno 1 (06:00–14:00)**.
> Moneda: MXN. Energía: tarifa de referencia **$2.48 MXN/kWh**.

## Resumen de planta

| Indicador | Valor | Meta | Estado |
|---|---:|---:|---|
| Producción planificada | 18,200 piezas | 18,200 | — |
| Producción real | 16,675 piezas | 18,200 | 91.6% |
| Brecha contra plan | -1,525 piezas | 0 | Rojo |
| OEE ponderado | 80.0% | >= 85.0% | Ámbar |
| Scrap total | 438 piezas | <= 2.0% | 2.63%, rojo |
| Retrabajo total | 286 piezas | <= 1.0% | 1.72%, rojo |
| Costo de scrap | $184,920 MXN | <= $120,000 | Rojo |
| Costo de retrabajo | $64,350 MXN | <= $40,000 | Rojo |
| Costo de no calidad | $249,270 MXN | <= $160,000 | Rojo |
| Tiempo muerto | 307 min | <= 180 min | Rojo |
| Consumo de energía | 34,913 kWh | <= 32,000 | Ámbar |
| Costo de energía | $86,584 MXN | <= $79,360 | Ámbar |
| Costo energético por pieza | $5.19 MXN | <= $4.75 | Ámbar |

## Desempeño por línea

| Línea | Proceso | Plan | Real | Cumplimiento | OEE | Scrap | Tiempo muerto | kWh/pieza | Estado |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| HPDC-01 | Fundición a presión | 4,800 | 4,320 | 90.0% | 78.6% | 121 (2.8%) | 64 min | 2.84 | Ámbar |
| HPDC-02 | Fundición a presión | 4,200 | 3,990 | 95.0% | 83.7% | 84 (2.1%) | 47 min | 2.55 | Ámbar |
| INJ-03 | Inyección de plástico | 6,200 | 5,890 | 95.0% | 85.8% | 88 (1.5%) | 84 min | 0.68 | Verde |
| SPM-04 | Molde semipermanente | 3,000 | 2,475 | 82.5% | 71.9% | 145 (5.9%) | 112 min | 3.42 | Rojo |

## Brecha contra plan

1. **SPM-04:** -525 piezas; explica 34.4% de la brecha total.
2. **HPDC-01:** -480 piezas; explica 31.5%.
3. **INJ-03:** -310 piezas; explica 20.3%.
4. **HPDC-02:** -210 piezas; explica 13.8%.

## Principales causas de tiempo muerto

| Ranking | Línea | Causa | Minutos | Impacto estimado |
|---:|---|---|---:|---:|
| 1 | SPM-04 | Inestabilidad de temperatura del molde | 52 | 245 piezas |
| 2 | INJ-03 | Cambio de color / purga extendida | 45 | 175 piezas |
| 3 | SPM-04 | Baja presión hidráulica | 34 | 160 piezas |
| 4 | HPDC-01 | Desviación de temperatura de horno | 28 | 135 piezas |
| 5 | HPDC-02 | Espera de material liberado | 26 | 105 piezas |

## Scrap y retrabajo

- Defecto dominante: **porosidad**, 122 piezas (27.9% del scrap).
- Línea con mayor impacto: **SPM-04**, 145 piezas de scrap y 96 de retrabajo.
- SPM-04 concentra **$91,460 MXN** del costo de no calidad (36.7% del total).
- Lote **BCR-241014-A17**: 320 piezas retenidas por porosidad detectada en rayos X.
- La coincidencia de baja presión hidráulica, variación térmica y porosidad es una
  **hipótesis prioritaria**, no una causa raíz confirmada.
- Validación requerida: OT-10482, parámetros de proceso, muestra ampliada y revisión de
  rayos X antes de liberar producto.

## Energía

- Mayor consumo por pieza: **SPM-04, 3.42 kWh/pieza**.
- Mayor consumo total: **HPDC-01, 12,269 kWh**.
- SPM-04 consume 20.0% más energía por pieza que HPDC-01 y tiene el menor OEE.
- Oportunidad estimada: llevar SPM-04 a 2.95 kWh/pieza ahorraría aproximadamente
  **1,163 kWh por turno**, equivalentes a **$2,884 MXN por turno**.

## Recomendación ejecutiva

Priorizar la estabilización de **SPM-04**: combina menor OEE, mayor scrap/retrabajo,
$91,460 MXN de costo de no calidad, mayor energía por pieza y 34.4% de la brecha.
El siguiente foco es **HPDC-01** por desviación de horno. Toda intervención debe
coordinarse con Mantenimiento y conservar la aprobación humana.
