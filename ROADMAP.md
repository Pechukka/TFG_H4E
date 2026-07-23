# ROADMAP — Hands4Events

Fases en orden. **Una fase = una rama = un commit final = un push.** No pases a la
siguiente sin cerrar la anterior (`flutter analyze` limpio + push). Marca `[x]` al terminar.

Leyenda: 🎯 pedido por mí · 💡 propuesto por Claude · 🔧 requiere decisión/ajuste mío.

---

## Fase 0 — Baseline y seguridad `chore` ✅
Dejar el proyecto sano y seguro antes de meterle mano.

- [x] `flutter pub get` + `flutter analyze` de partida; anota los problemas actuales.
      → Baseline **limpio**: `No issues found!`.
- [x] 🎯 Reescribir `README.md` (ahora es el stub de Flutter): descripción real del
      proyecto, stack, cómo arrancar worker (móvil) y admin (web), estructura de carpetas.
- [x] 🔧 Sacar la **API key de Google Maps** de `lib/core/constants.dart` del código, o
      dejarla restringida por app/dominio. Marcar con `// 🔧 AJUSTAR`.
      → En Dart vía `--dart-define=GOOGLE_MAPS_API_KEY`; en Android nativo vía
      `android/local.properties` (`mapsApiKey=...`). Key nueva y restringida: la generas tú.
- [x] 💡 Crear `firestore.rules` y `storage.rules` con reglas **por rol**:
      - worker: lee/edita solo SU disponibilidad, SUS fichajes, SU perfil; lee eventos
        donde está asignado; lee sus nóminas.
      - admin: acceso de gestión completo.
      (Redactar las reglas; el `firebase deploy` lo hago yo.)
- [x] Commit: `chore: baseline, README y reglas de seguridad` → push.

---

## Fase 1 — Panel web admin: dashboard + pulido `feat(admin)` ✅
Hoy el admin solo tiene 3 secciones (Trabajadores, Eventos, Nóminas) y ningún resumen.

- [x] 💡 **Añadir sección Dashboard** como pantalla de entrada del admin
      (nueva entrada en `AdminSection` + `AdminSidebar` + `AdminShell`). Tarjetas KPI:
      - nº de trabajadores activos
      - eventos próximos (siguientes 7 días)
      - horas fichadas del mes en curso
      - nóminas pendientes de enviar este mes
      - lista corta "próximos eventos" con su cobertura (nº de asignados)
      → `nota:` la cobertura se muestra como "nº de asignados" (no "X/Y") porque el máximo
      por rol (`plazasPorRol`) todavía no existe; llega en la Fase 2.
- [x] 🎯 **Pulido visual del panel** (sin salirse de `AppTheme`, minimalista):
      jerarquía tipográfica, espaciados consistentes, estados hover/seleccionado del
      sidebar, tablas/listas más legibles, estados vacíos ("aún no hay eventos") decentes.
- [x] 💡 **Buscador + filtros** en Trabajadores (por nombre) y Eventos (por fecha/estado).
- [x] Commit: `feat(admin): dashboard, buscadores y refinamiento visual` → push.

---

## Fase 2 — Feed de eventos tipo Tinder `feat` (EL NÚCLEO) — spec cerrada ✅
🎯 **Cambio de modelo, no un retoque.** El admin publica eventos sin asignar a nadie, y el
worker se postula/rechaza cada evento deslizando cartas (tipo Tinder). Las dos decisiones ya
están tomadas. **No improvisar el modelo de datos: seguir esta spec.**

### Decisiones tomadas
1. **Un evento pide VARIOS roles a la vez**, con nº de plazas por rol
   (ej. 3× H4ndMontaje + 1× Coordinador).
2. **Swipe derecha = el worker SE POSTULA.** No entra directo. El admin confirma después.

### Modelo de datos

**`eventos` (campos nuevos):**
- `plazasPorRol: {rol: int}` — plazas objetivo por rol. Ej. `{'H4ndMontaje': 3, 'Coordinador': 1}`
- `estado: string` — `'borrador' | 'publicado' | 'finalizado'`. Solo los `publicado` entran
  en el feed del worker.

Se mantienen tal cual `trabajadoresIds`, `trabajadoresRoles` y `trabajadoresInfo`: pasan a
significar **los CONFIRMADOS** por el admin. El admin sigue dentro como `Coordinador` en
`trabajadoresRoles` y con `esAdmin: true` en `trabajadoresInfo`.

**Compatibilidad:** eventos antiguos no tienen `estado` ni `plazasPorRol`. En Dart, `estado`
ausente → trátalo como `'publicado'` solo para la vista admin; el filtro de "fecha futura" ya
los deja fuera del feed. En las reglas, sin `estado` no son legibles por workers no asignados,
y eso es correcto: nadie debe verlos en el feed.

**`postulaciones` (colección NUEVA):**
```
{
  eventoId: string,
  trabajadorId: string,
  rol: string,        // el puesto al que se postula
  estado: string,     // 'pendiente' | 'rechazado_por_worker' | 'confirmado' | 'descartado'
  createdAt: timestamp
}
```
- Swipe **izquierda** → doc con `estado: 'rechazado_por_worker'` (esa carta no vuelve a salir).
- Swipe **derecha** → doc con `estado: 'pendiente'`.
- Admin **confirma** → `estado: 'confirmado'` **y** añade al worker a `trabajadoresIds` /
  `trabajadoresRoles` / `trabajadoresInfo` del evento (con nombre y rol; **sin teléfono**,
  para no filtrarlo en el feed).
- Admin **descarta** → `estado: 'descartado'`.

### 2A — Admin: publicar evento sin asignar ✅
- [x] Al crear/editar un evento: quitar la selección de trabajadores. Se define `plazasPorRol`
      y el `estado`.
- [x] Pantalla de **postulaciones del evento**: lista de los `pendiente`, agrupados por rol,
      con botones **Confirmar** / **Descartar**.
- [x] **Cobertura en vivo por rol**: "Montaje 2/3 · Coordinador 0/1", contando `confirmado`
      frente a `plazasPorRol`.
- [x] 🎯 El evento se crea y publica **aunque no se llenen las plazas**. Sin bloqueos.
- [x] Al confirmar, si el rol ya está lleno, avisar pero **dejar decidir al admin**.

### 2B — Worker: feed de cartas ✅
- [x] Sustituir la pantalla de calendario/disponibilidad por el **feed** (renombrar el ítem de
      navegación, p.ej. "Ofertas").
- [x] Pila de cartas. Cada carta: título, fecha/hora, ubicación, descripción, cobro/hora y
      **plazas libres por rol**.
- [x] **Derecha = postularse · Izquierda = rechazar.**
- [x] Al postularse: si hay **más de un rol con plazas libres**, un selector rápido "¿Para qué
      puesto?". Si solo hay uno, se elige automáticamente.
- [x] **Qué cartas se muestran:** eventos con `estado == 'publicado'`, `fechaInicio` futura, y
      sobre los que el worker **no tenga ya una postulación**.
      ⚠️ Firestore no sabe hacer "not in" contra otra colección. Sigue el patrón del proyecto:
      consulta los eventos publicados, consulta **sus propias** postulaciones
      (`where trabajadorId == uid`) y **cruza/filtra en Dart**. Sin índices compuestos.
- [x] Pantalla **"Mis postulaciones"**: ver las pendientes y las confirmadas.

### 2C — Reglas de seguridad (obligatorio, va en el mismo commit) ✅
- [x] `eventos.read`: permitir si es admin, **o** el uid está en `trabajadoresIds`, **o**
      `resource.data.estado == 'publicado'`.
- [x] Nueva sección `postulaciones`:
      - worker: **lee, crea y borra solo las suyas** (`trabajadorId == uid`).
      - worker: al crear, `estado` solo puede ser `'pendiente'` o `'rechazado_por_worker'`.
        **Nunca puede escribir `'confirmado'`** — eso es exclusivo del admin.
      - admin: acceso total.
- [x] `eventos.update` sigue siendo solo del admin (el worker NO se añade a sí mismo a
      `trabajadoresIds`; lo hace el admin al confirmar).

### 2D — Limpieza (al final, no antes) ✅
- [x] Retirar `disponibilidad`: `DisponibilidadService`, `disponibilidad_provider`,
      `modal_disponibilidad`, `calendario_screen`, el modelo y la sección de las reglas.
- [x] `AdminService.tieneDisponibilidad()` y todo lo que la use.
- [x] Borra el código, no lo dejes comentado.

- [x] `flutter analyze` limpio. Commits separados por bloque (2A, 2B, 2C, 2D). Push.
- [ ] No mergear a `main` sin autorización.

---

## Fase 3 — Funcionalidades nuevas (valor para la demo) `feat` ✅ (parcial)
💡 Ideas mías que hacen la app más creíble como producto. Cada una es un commit propio;
si alguna no la quieres, la saltamos.

- [x] **Estados de evento**: `borrador → publicado → finalizado` (el ciclo se amplía con
      `activo` en la Fase 5). Solo los `publicados` entran en el feed. Control de estado en
      la tarjeta del admin, filtro por estado y blindaje en reglas (solo postularse a
      `publicado`). → rama `fase-3-estados-evento`.
- [x] **Notificaciones push** al confirmar a un worker: aviso "Te han confirmado" en el mismo
      batch + campanita in-app. La Cloud Function `onNotificacionCreada` lo convierte en push.
      → rama `fase-3-notificaciones`.
- [ ] **Deshacer / mis eventos aceptados**: que el worker pueda retirarse antes de una fecha
      límite. — *no implementado (aparcado).*
- [ ] **Resumen/exportación de nóminas del mes** para el admin en un único PDF. — *no
      implementado (aparcado).*

---

## Fase 4 — Pulido final y material de presentación `chore` (en curso)
Para que la reunión con H4E entre por los ojos.

- [x] 💡 **Datos de ejemplo (seed)**: `scripts/seed-demo.js` (Node + firebase-admin) crea
      workers (3 con login real + 12 de relleno), eventos en los tres estados con fechas
      repartidas, postulaciones (pendientes/confirmadas) y notificaciones. Idempotente, con
      flag de borrado/reseed. → rama `fase-4-seed-demo`.
- [ ] Repaso visual final worker + admin; estados vacíos y de carga coherentes.
- [ ] `flutter analyze` totalmente limpio; probar los flujos principales a mano.
- [ ] 💡 Capturas / mini-guion de demo (qué enseñar y en qué orden) en un `DEMO.md`.

---

## Fase 5 — Ciclo de vida del evento y gestión del equipo `feat` — spec cerrada
🎯 Trabajo nuevo (no estaba planificado). Implementar por bloques (5A–5D), un commit por
bloque, parándose tras cada uno para revisión. **No improvisar el modelo de datos.**

### Contexto (estado actual, verificado)
- `estado` de evento hoy: `borrador | publicado | finalizado`. No existe "activo".
- El chat NO está gateado: cualquier confirmado puede abrirlo desde que se le confirma.
- `confirmar()` NO comprueba el cupo del rol (deja meter de más).
- Editar un evento SÍ modifica `plazasPorRol` (ya funciona).

### Decisiones tomadas (no reabrir)
1. Nuevo ciclo: `borrador → publicado → activo → finalizado`. **`activo` = grupo creado = chat abierto.**
2. Se llega a `activo` de dos formas: **auto** (al confirmarse la última plaza, equipo completo)
   o **manual** (el admin pulsa "crear grupo" aunque falten plazas).
3. **El chat solo está disponible si `estado == 'activo'`** (gateado en la app).
4. **Límite de cupo duro:** no se puede confirmar/añadir a un rol lleno; para meter uno más
   hay que editar el evento y subir las plazas de ese rol.
5. Quitar a un confirmado → su postulación pasa a `descartado` y su plaza queda libre.
6. Añadir desde el panel admin puede ser cualquier worker (estilo grupo de WhatsApp).
7. Al editar, no se permite bajar las plazas de un rol por debajo de los confirmados que ya tiene.

### Reglas de seguridad
Con `activo`, las reglas existentes ya se comportan bien y **no hace falta tocarlas**:
- `eventos.read` (admin | uid in trabajadoresIds | estado=='publicado'): un evento `activo` lo
  leen sus miembros (por `trabajadoresIds`) y desaparece del feed (deja de ser `publicado`).
- `postulaciones.create` exige `eventoPublicado`: en un evento `activo` ya no se puede postular
  por el feed (correcto; el admin añade a mano).
El gateo del chat por `activo` se hace **en la app** (UI), no en reglas (evitar un `get()` por
mensaje). No cambiar reglas salvo que algo lo exija; si lo exige, avisar antes.

### 5A — Visibilidad de cobertura (empezar por aquí, bajo riesgo)
- [ ] En la lista/tarjeta de eventos del admin, mostrar por evento **confirmados** (ya existe,
      en verde) **y postulaciones pendientes** (número, ámbar), sin entrar a "postulaciones".
- [ ] Opcional: desglose de cobertura por rol si cabe sin recargar la tarjeta.
- [ ] Commit: `feat(admin): mostrar postulaciones pendientes en la lista de eventos`.

### 5B — Ciclo de vida y activación del grupo (el núcleo)
- [ ] Añadir el estado `activo` al modelo/flujo (`borrador | publicado | activo | finalizado`).
- [ ] **Auto-activación:** en `confirmar()`, tras añadir al worker, si todos los roles quedan
      cubiertos (confirmados por rol == `plazasPorRol`, excluyendo al admin), poner
      `estado = 'activo'` en el mismo batch.
- [ ] **Activación manual:** botón "Crear grupo / Activar" en eventos `publicado`, aunque falten
      plazas (avisa de la cobertura pero deja activar).
- [ ] **Límite de cupo en `confirmar()`:** si el rol ya está lleno, NO confirmar; avisar. Cambia
      el comportamiento actual (hoy no comprueba).
- [ ] **Gateo del chat:** el chat solo se abre si `estado == 'activo'`; si no, ocultar/deshabilitar
      el acceso con un aviso ("El grupo aún no está creado").
- [ ] Commit(s): `feat: ciclo de vida del evento (estado activo, auto/manual, cupo, chat gateado)`.

### 5C — Gestión del equipo (añadir / quitar integrantes)
- [ ] **Añadir integrante** (respetando cupo): elegir worker + rol con plaza libre; bloquear si
      el rol está lleno. Escribe en `trabajadoresIds/Roles/Info` (sin teléfono).
- [ ] **Quitar integrante:** lo saca de `trabajadoresIds/Roles/Info` y su postulación (si existe)
      pasa a `descartado`. Libera la plaza. No permitir quitar al admin creador.
- [ ] **Guarda en edición:** al editar `plazasPorRol`, impedir bajar un rol por debajo de sus
      confirmados actuales. Subir siempre permitido.
- [ ] Recalcular cobertura tras añadir/quitar; al quitar, el evento puede seguir `activo` (no se
      desactiva solo).
- [ ] Commit: `feat(admin): añadir y quitar integrantes del evento respetando cupo`.

### 5D — Chat de eventos en el panel admin
- [ ] Surtir el chat del evento en el **panel web admin** (hoy solo desde el móvil worker). Las
      reglas ya permiten al admin (es miembro como Coordinador): es sobre todo UI.
- [ ] La zona de "participantes" del chat admin es donde pueden vivir las acciones de 5C.
- [ ] Commit: `feat(admin): ver y participar en el chat del evento desde el panel web`.

> `flutter analyze` limpio antes de cada commit. Rama `fase-5-ciclo-evento`. Parar tras cada
> bloque para revisión; no mergear sin OK.
> Nota demo: los eventos del seed ya `publicado` y completos no se vuelven `activo` solos (la
> auto-activación salta al confirmar, no retroactivamente). Si se quiere alguno `activo`,
> activarlo a mano o re-sembrar con ese estado.

---

### Notas para Claude Code
- Antes de empezar CADA fase: relee la sección correspondiente y el `CLAUDE.md`.
- Donde veas 🔧 **para antes de codificar**, pregúntame; no decidas tú solo cambios de modelo
  de datos o de esquema Firestore.
- Prioridad siempre: **que no rompa nada existente** > funcionalidad nueva > estética.
