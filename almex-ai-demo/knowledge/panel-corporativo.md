# Panel Operativo — Cuentas Corporativas ALMEX (fuente de verdad)

**Versión:** 1.0 · **Corte de datos:** 12 de enero de 2026, 08:00 (hora del centro) · **Área:** Torre de Control / Cuentas Corporativas
**Aviso:** Clientes, sucursales, guías y datos **ficticios**, elaborados únicamente para fines de demostración.

> Este panel es **exclusivo de la Unidad de Negocio "Cuentas Corporativas (Operaciones)"**. Permite consultar el **estado agregado del portafolio de embarques**: cuántos van en tránsito, cuáles tienen riesgo de retraso y qué **sucursal de origen (CEDIS/Hub)** concentra más incidencias.
> Para datos financieros por cliente (revenue, margen, costo) **no** aplica: esos son exclusivos de **Logística Interna (Management)**.

---

## Portafolio corporativo activo (14 embarques)

| Guía | Cliente | Sucursal origen (CEDIS/Hub) | Estatus | Riesgo de retraso | Incidencia | ETA |
|---|---|---|---|---|---|---|
| ALM-CORP-77012 | Comercializadora del Bajío | CEDIS Tepotzotlán (CDMX) | En tránsito | No | — | 13-ene 11:00 |
| ALM-CORP-77013 | Retail Norte | CEDIS Apodaca (Monterrey) | En reparto | No | — | Hoy ~16:00 |
| ALM-CORP-77014 | Farmacéutica Contoso | CEDIS El Salto (Guadalajara) | Detenido | Sí (detenido) | Revisión en punto de inspección | 13-ene tarde |
| ALM-CORP-77015 | Comercializadora del Bajío | CEDIS Tepotzotlán (CDMX) | En tránsito | **Sí** | Retraso por clima (corredor Pacífico) | 16-ene (+1 día) |
| ALM-CORP-77016 | Retail Norte | CEDIS Apodaca (Monterrey) | En tránsito | No | — | 14-ene 10:00 |
| ALM-CORP-77017 | Grupo Ferretero MX | CEDIS El Salto (Guadalajara) | Detenido | Sí (detenido) | Domicilio incorrecto / destinatario ausente | 14-ene |
| ALM-CORP-77018 | Distribuidora Maya | CEDIS Vallejo (CDMX) | En reparto | No | — | Hoy ~15:00 |
| ALM-CORP-77019 | Farmacéutica Contoso | CEDIS El Salto (Guadalajara) | En tránsito | **Sí** | Inspección documental en punto de revisión | 15-ene |
| ALM-CORP-77020 | Retail Norte | CEDIS Apodaca (Monterrey) | Entregado | No | — | Entregado 10-ene |
| ALM-CORP-77021 | Grupo Ferretero MX | CEDIS El Salto (Guadalajara) | Detenido | Sí (detenido) | Paquete dañado — caso #INC-5601 | Por definir |
| ALM-CORP-77022 | Comercializadora del Bajío | CEDIS Tepotzotlán (CDMX) | En tránsito | No | — | 15-ene |
| ALM-CORP-77023 | Distribuidora Maya | CEDIS Vallejo (CDMX) | En tránsito | **Sí** | Saturación en hub Querétaro | 16-ene |
| ALM-CORP-77024 | Retail Norte | CEDIS Apodaca (Monterrey) | Detenido | Sí (detenido) | Destinatario ausente (1.er intento) | 14-ene |
| ALM-CORP-77025 | Comercializadora del Bajío | CEDIS Tepotzotlán (CDMX) | Entregado | No | — | Entregado 11-ene |

---

## Resumen operativo (pre-calculado — usa estas cifras exactas)

### Embarques por estatus
| Estatus | Cantidad | Guías |
|---|---|---|
| **En tránsito** | **6** | 77012, 77015, 77016, 77019, 77022, 77023 |
| En reparto | 2 | 77013, 77018 |
| **Detenido (con incidencia)** | **4** | 77014, 77017, 77021, 77024 |
| Entregado | 2 | 77020, 77025 |
| **Total activo** | **14** | — |

> "Embarques activos" = todos menos los ya entregados (12 en curso). "En tránsito" = **6**.

### Entregas con riesgo de retraso (7)
Se consideran **en riesgo** los embarques con bandera de retraso o ya detenidos por incidencia.

| Guía | Sucursal origen | Motivo | ETA impactada |
|---|---|---|---|
| ALM-CORP-77015 | CEDIS Tepotzotlán | Clima (corredor Pacífico) | 16-ene (+1 día) |
| ALM-CORP-77019 | CEDIS El Salto | Inspección documental | 15-ene |
| ALM-CORP-77023 | CEDIS Vallejo | Saturación hub Querétaro | 16-ene |
| ALM-CORP-77014 | CEDIS El Salto | Revisión en inspección (detenido) | 13-ene tarde |
| ALM-CORP-77017 | CEDIS El Salto | Domicilio incorrecto (detenido) | 14-ene |
| ALM-CORP-77021 | CEDIS El Salto | Paquete dañado (detenido) | Por definir |
| ALM-CORP-77024 | CEDIS Apodaca | Destinatario ausente (detenido) | 14-ene |

- **En riesgo pero aún en movimiento (3):** 77015, 77019, 77023.
- **Ya detenidos/impactados (4):** 77014, 77017, 77021, 77024.

### Incidencias por sucursal de origen (CEDIS/Hub)
| Sucursal origen | Incidencias activas (detenidos) | En riesgo (en movimiento) | Total con afectación |
|---|---|---|---|
| **CEDIS El Salto (Guadalajara)** | **3** (77014, 77017, 77021) | 1 (77019) | **4** |
| CEDIS Apodaca (Monterrey) | 1 (77024) | 0 | 1 |
| CEDIS Tepotzotlán (CDMX) | 0 | 1 (77015) | 1 |
| CEDIS Vallejo (CDMX) | 0 | 1 (77023) | 1 |

> **Sucursal que genera más incidencias: `CEDIS El Salto (Guadalajara)`** — 3 embarques detenidos (revisión en inspección, domicilio incorrecto y paquete dañado) más 1 en riesgo. Recomendación: revisar procesos de documentación de traslado y empaque en ese CEDIS.

---

## Notas de lectura para Alma (modo corporativo)
- Cuando el usuario corporativo pregunte por **totales o agregados** ("cuántos", "cuáles", "qué sucursal"), responde con las **cifras pre-calculadas** de este panel y, si ayuda, lista las guías.
- Ofrece **desglosar**: por ejemplo, tras dar el conteo de "en tránsito", pregunta si quiere el detalle guía por guía.
- Para riesgo de retraso, prioriza mencionar el **motivo** y el **ETA impactado**.
- Para incidencias por sucursal, nombra la sucursal top y da una **recomendación accionable** (proceso a revisar).
- No mezcles el portafolio corporativo con guías de autoservicio (`ALM-XXXXXX`): son cuentas distintas.
