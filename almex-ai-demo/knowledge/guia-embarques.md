# Guía de Embarques — Rastreo ALMEX (fuente de verdad)

**Versión:** 2.1 · **Corte de datos:** 12 de enero de 2026, 08:00 (hora del centro) · **Área:** Operaciones / Atención a Clientes
**Aviso:** Números de guía, clientes y datos **ficticios**, elaborados únicamente para fines de demostración.

> Formato de guía: **`ALM-XXXXXX`** (clientes/autoservicio) · **`ALM-CORP-XXXXX`** (cuentas corporativas).
> Estatus posibles: *En preparación · En tránsito · En reparto · Entregado · Detenido (con incidencia) · Devolución*.

---

## Embarques de clientes (autoservicio)

### ALM-100234
| Campo | Valor |
|---|---|
| **Estatus** | **En tránsito** |
| **Origen** | CDMX — Centro de distribución Vallejo |
| **Destino** | Guadalajara, Jalisco |
| **Servicio** | Terrestre Estándar |
| **Última lectura** | Hub El Marqués, Querétaro (11-ene 21:40) |
| **ETA (llegada estimada)** | **15 de enero de 2026** |
| **Ventana de entrega** | 09:00–18:00 |
| **Incidencia** | Ninguna |

### ALM-100235
| Campo | Valor |
|---|---|
| **Estatus** | **En reparto** (out for delivery) |
| **Origen** | Monterrey, Nuevo León |
| **Destino** | CDMX — Colonia Del Valle |
| **Servicio** | Express Aéreo |
| **Última lectura** | Unidad de reparto 42, CDMX (12-ene 07:15) |
| **ETA (llegada estimada)** | **Hoy**, antes de las 14:00 |
| **Ventana de entrega** | 09:00–14:00 |
| **Incidencia** | Ninguna |

### ALM-100236
| Campo | Valor |
|---|---|
| **Estatus** | **Detenido (con incidencia)** |
| **Origen** | CDMX — Vallejo |
| **Destino** | Mérida, Yucatán |
| **Servicio** | Terrestre Estándar |
| **Última lectura** | Hub Mérida (11-ene 18:05) |
| **Incidencia** | **Domicilio incorrecto / destinatario ausente** (1.er intento fallido) |
| **Siguiente paso** | Se requiere confirmar/corregir domicilio; 2.º intento programado |
| **ETA (reprogramada)** | **14 de enero de 2026** |

### ALM-100237
| Campo | Valor |
|---|---|
| **Estatus** | **En tránsito** |
| **Origen** | Tijuana, Baja California |
| **Destino** | CDMX — Iztapalapa |
| **Servicio** | Carga consolidada |
| **Última lectura** | Hub Guadalajara (12-ene 03:20) |
| **Incidencia** | **Retraso por clima** (lluvia intensa en el corredor del Pacífico) |
| **ETA (reprogramada)** | **17 de enero de 2026** (+1 día vs. original) |
| **Ventana de entrega** | 09:00–18:00 |

### ALM-100238
| Campo | Valor |
|---|---|
| **Estatus** | **Entregado** |
| **Origen** | Guadalajara, Jalisco |
| **Destino** | Puebla, Puebla |
| **Servicio** | Express Terrestre |
| **Fecha de entrega** | 10 de enero de 2026, 12:36 |
| **Comprobante (POD)** | Firma de recibido: "R. López" |
| **Incidencia** | Ninguna |

### ALM-100239
| Campo | Valor |
|---|---|
| **Estatus** | **En tránsito** |
| **Origen** | CDMX — Vallejo |
| **Destino** | Cancún, Quintana Roo |
| **Servicio** | Aéreo |
| **Última lectura** | Centro de carga aérea AICM (12-ene 06:00) |
| **ETA (llegada estimada)** | **14 de enero de 2026** |
| **Ventana de entrega** | 10:00–19:00 |
| **Incidencia** | Ninguna |

### ALM-100240
| Campo | Valor |
|---|---|
| **Estatus** | **Detenido (con incidencia)** |
| **Origen** | León, Guanajuato |
| **Destino** | Toluca, Estado de México |
| **Servicio** | Terrestre Estándar |
| **Última lectura** | Hub Querétaro (11-ene 22:10) |
| **Incidencia** | **Paquete dañado en tránsito** — abierto caso de investigación #INC-5582 |
| **Siguiente paso** | Valuación y contacto del ejecutivo de atención en 24–48 h |
| **ETA** | Por definir (sujeto al caso) |

---

## Embarques de cuentas corporativas

### ALM-CORP-77012
| Campo | Valor |
|---|---|
| **Cliente** | Comercializadora del Bajío S.A. |
| **Estatus** | **En tránsito** |
| **Origen** | CDMX — Centro corporativo Tepotzotlán |
| **Destino** | Aguascalientes, Ags. (5 tarimas) |
| **Servicio** | Corporativo Dedicado (FTL) |
| **Última lectura** | Caseta Palmillas (12-ene 05:45) |
| **ETA (llegada estimada)** | **13 de enero de 2026**, 11:00 |
| **Incidencia** | Ninguna |

### ALM-CORP-77013
| Campo | Valor |
|---|---|
| **Cliente** | Retail Norte S. de R.L. |
| **Estatus** | **En reparto** |
| **Origen** | Monterrey — CEDIS Apodaca |
| **Destino** | 8 sucursales zona metropolitana Monterrey |
| **Servicio** | Distribución de última milla (multiparada) |
| **Avance** | 3 de 8 paradas entregadas (12-ene 08:00) |
| **ETA (fin de ruta)** | **Hoy**, aprox. 16:00 |
| **Incidencia** | Ninguna |

### ALM-CORP-77014
| Campo | Valor |
|---|---|
| **Cliente** | Farmacéutica Contoso |
| **Estatus** | **Detenido (con incidencia)** |
| **Origen** | Guadalajara — CEDIS El Salto |
| **Destino** | CDMX — almacén cliente |
| **Servicio** | Corporativo Dedicado (cadena de frío) |
| **Incidencia** | **Revisión en punto de inspección** (documentación de traslado) |
| **Siguiente paso** | Liberación esperada en 6–8 h; se notificará al ejecutivo de cuenta |
| **ETA (reprogramada)** | **13 de enero de 2026**, tarde |

---

## Notas de lectura para Alma
- Si el estatus es **"En reparto"**, el embarque ya salió a entrega: **no** admite cambio de domicilio en línea (ver Política de Entregas).
- Si hay **incidencia**, menciónala explícitamente y da el **siguiente paso** y el **ETA reprogramado** cuando exista.
- Si la guía **no** está en esta lista, indícalo y ofrece abrir un caso o verificar el número.
