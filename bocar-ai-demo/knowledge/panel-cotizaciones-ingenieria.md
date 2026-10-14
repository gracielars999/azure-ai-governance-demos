# Panel sintético — Ingeniería y Cotizaciones

> Datos ficticios para demostrar un agente de RFQ con conocimiento de ingeniería.

## RFQ activo

| Campo | Valor |
|---|---|
| RFQ | RFQ-26-184 |
| Cliente | OEM-D (anonimizado) |
| Componente | Carcasa de aluminio para módulo térmico de vehículo eléctrico |
| Proceso | HPDC + maquinado CNC + prueba de hermeticidad |
| Volumen anual | 420,000 piezas |
| SOP solicitado | Julio 2027 |
| Fecha límite de respuesta | 21-oct-2026 |
| Aleación | A380 |
| Moneda | MXN por pieza |

## Fuentes simuladas

| Fuente | Documento | Revisión | Evidencia |
|---|---|---|---|
| PLM | SPEC-TC-8842 | Rev C | Tolerancias, material y prueba de hermeticidad |
| PLM | PFMEA-TC-4410 | Rev B | Riesgos de porosidad y fuga |
| repositorio documental | RFQ-26-184-commercial.pdf | 1.0 | Volumen, SOP y términos solicitados |
| Histórico plataforma analítica | Q-24-071 | Final | Proyecto comparable, 380K piezas/año |
| Histórico plataforma analítica | Q-25-109 | Final | Proyecto comparable, 450K piezas/año |

## Históricos comparables

| Cotización | Volumen anual | Precio final | Margen | Lead time | Resultado |
|---|---:|---:|---:|---:|---|
| Q-24-071 | 380,000 | $216.40 | 18.4% | 18 semanas | Ganada |
| Q-25-109 | 450,000 | $224.10 | 16.8% | 20 semanas | Ganada |
| Q-25-133 | 300,000 | $238.50 | 21.1% | 17 semanas | Perdida por precio |

## Costeo preliminar RFQ-26-184

| Concepto | MXN/pieza |
|---|---:|
| Aluminio | $68.40 |
| Conversión de fundición | $41.20 |
| Maquinado CNC | $32.80 |
| Calidad y prueba | $8.60 |
| Overhead | $15.70 |
| Logística | $6.30 |
| Contingencia scrap/ramp-up | $9.00 |
| **Costo total estimado** | **$182.00** |

- Margen objetivo: **18.0%**.
- Precio sugerido preliminar: **$221.95 MXN/pieza**.
- Ingreso anual estimado al volumen nominal: **$93.22M MXN**.
- Banda de sensibilidad recomendada: $217.50–$226.50 MXN/pieza.

## Borrador recomendado

Proponer **$221.95 MXN/pieza**, sujeto a validación de Compras, Ingeniería, Finanzas y
Capacidad. Citar SPEC-TC-8842 Rev C y los comparables Q-24-071/Q-25-109.

## Controles obligatorios

- El resultado es un **borrador**, no una oferta vinculante.
- No enviar al cliente ni crear registros sin aprobación humana.
- Confirmar capacidad, inversión, herramental, tipo de cambio y términos comerciales.
- Respetar permisos de PLM/repositorio documental; no revelar documentos fuera del dominio.

