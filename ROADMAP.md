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

## Fase 3 — Funcionalidades nuevas (valor para la demo) `feat`
💡 Ideas mías que hacen la app más creíble como producto. Cada una es un commit propio;
si alguna no la quieres, la saltamos.

- [ ] **Estados de evento**: `borrador → publicado → en curso → finalizado`. Solo los
      `publicados` entran en el feed de cartas del worker. Ordena el dashboard y el feed.
- [ ] **Notificaciones push** en los momentos clave: nuevo evento publicado que te encaja,
      te confirman en un evento (si va con confirmación), cambia la hora, nómina disponible.
      Solo móvil (web ya sabemos que no).
- [ ] **Deshacer / mis eventos aceptados**: que el worker pueda ver los eventos que ha
      aceptado y, si hace falta, retirarse antes de una fecha límite (libera plaza, avisa admin).
- [ ] **Resumen/exportación de nóminas del mes** para el admin en un único PDF o carpeta.
- [ ] Commits: uno por funcionalidad (`feat: estados de evento`, `feat: confirmacion worker`…).

---

## Fase 4 — Pulido final y material de presentación `chore`
Para que la reunión con H4E entre por los ojos.

- [ ] 💡 **Datos de ejemplo (seed)**: script o botón oculto de admin que crea trabajadores,
      eventos y disponibilidades de mentira para hacer la demo con la app "llena", no vacía.
- [ ] Repaso visual final worker + admin; estados vacíos y de carga coherentes.
- [ ] `flutter analyze` totalmente limpio; probar los flujos principales a mano.
- [ ] 💡 Capturas / mini-guion de demo (qué enseñar y en qué orden) en un `DEMO.md`.
- [ ] Commit: `chore: seed de demo, pulido final y guion` → push.

---

### Notas para Claude Code
- Antes de empezar CADA fase: relee la sección correspondiente y el `CLAUDE.md`.
- Donde veas 🔧 **para antes de codificar**, pregúntame; no decidas tú solo cambios de modelo
  de datos o de esquema Firestore.
- Prioridad siempre: **que no rompa nada existente** > funcionalidad nueva > estética.
