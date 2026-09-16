# Procedimiento Operativo de Contracargos (Chargebacks) — Banco Contoso

**Versión:** 2.1 · **Área:** Operaciones de Medios de Pago

## Flujo del proceso

1. **Recepción:** el cliente presenta la disputa por cualquier canal. El agente registra el caso y genera un folio (formato `DISP-AAAAMMDD-#####`).
2. **Clasificación:** el agente identifica el tipo de caso (fraude, no recibido, defectuoso, duplicado, suscripción) y valida la ventana de tiempo.
3. **Validación de elegibilidad:** se verifica contra la Política de Disputas v3.2 (sección 5).
4. **Crédito provisional:** si el monto es ≤ $2,500 MXN y el caso es elegible, se aplica crédito provisional inmediato. Montos mayores requieren aprobación (ver umbrales).
5. **Presentación a la red:** Operaciones presenta el contracargo a Visa/Mastercard con la documentación y el código de razón correspondiente.
6. **Respuesta del comercio:** el comercio puede aceptar o presentar representación (re-presentment) con evidencia.
7. **Resolución:** si la red falla a favor del cliente, el crédito se hace definitivo. Si falla a favor del comercio, se re-aplica el cargo con aviso previo de 5 días.
8. **Cierre y notificación:** se documenta la decisión y se notifica al cliente por su canal preferido.

## Códigos de razón frecuentes (red de pagos)

| Código | Motivo | Tipo |
|---|---|---|
| 10.4 | Fraude — transacción sin tarjeta presente | Fraude |
| 13.1 | Mercancía/servicios no recibidos | No recibido |
| 13.3 | Producto o servicio defectuoso | Defectuoso |
| 12.6 | Pago duplicado | Duplicado |
| 13.2 | Suscripción cancelada | Suscripción |

## SLA operativos

- Registro del caso: inmediato.
- Aplicación de crédito provisional elegible: máximo 48 horas.
- Presentación del contracargo a la red: máximo 5 días hábiles desde la clasificación.
- Notificación de resolución al cliente: dentro de 24 horas de recibir el fallo.

## Métricas de calidad

- **Tasa de resolución a favor del cliente:** objetivo ≥ 70%.
- **Tiempo promedio de resolución:** objetivo ≤ 12 días hábiles.
- **Reincidencia de disputas por comercio:** se monitorea para detectar comercios de alto riesgo.
