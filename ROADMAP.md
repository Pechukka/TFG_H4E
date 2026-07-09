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

## Fase 1 — Panel web admin: dashboard + pulido `feat(admin)`
Hoy el admin solo tiene 3 secciones (Trabajadores, Eventos, Nóminas) y ningún resumen.

- [ ] 💡 **Añadir sección Dashboard** como pantalla de entrada del admin
      (nueva entrada en `AdminSection` + `AdminSidebar` + `AdminShell`). Tarjetas KPI:
      - nº de trabajadores activos
      - eventos próximos (siguientes 7 días)
      - horas fichadas del mes en curso
      - nóminas pendientes de enviar este mes
      - lista corta "próximos eventos" con su cobertura (X/Y roles cubiertos)
- [ ] 🎯 **Pulido visual del panel** (sin salirse de `AppTheme`, minimalista):
      jerarquía tipográfica, espaciados consistentes, estados hover/seleccionado del
      sidebar, tablas/listas más legibles, estados vacíos ("aún no hay eventos") decentes.
- [ ] 💡 **Buscador + filtros** en Trabajadores (por nombre) y Eventos (por fecha/estado).
- [ ] Commit: `feat(admin): dashboard, buscadores y refinamiento visual` → push.

---

## Fase 2 — Feed de eventos tipo Tinder `feat` (EL NÚCLEO)
🎯 **Cambio de modelo, no un retoque.** Se elimina el sistema de "el worker programa su
disponibilidad y el admin cuadra contra ella". Se sustituye por: **el admin publica eventos
sin asignar a nadie, y el worker acepta/rechaza cada evento deslizando cartas (tipo Tinder).**

**Lo que desaparece / se jubila:**
- Colección `disponibilidad` y su lógica de emparejamiento (`AdminService.tieneDisponibilidad`,
  `DisponibilidadService`, `disponibilidad_provider`, `modal_disponibilidad`). No lo borres de
  golpe: primero monta lo nuevo, y en la fase de limpieza retiramos lo viejo.
- La pantalla de **calendario** del worker (`calendario_screen.dart`) como sitio para marcar
  disponibilidad. Se reemplaza por el feed de cartas (y se renombra el ítem de navegación,
  p.ej. "Ofertas" / "Eventos disponibles").

### 2A — Lado admin: crear evento SIN asignar
- [ ] Al crear/editar un evento, quitar toda la parte de "elegir entre disponibles".
- [ ] El evento se publica con: título, fecha/hora, ubicación, descripción, cobro/hora,
      **nº máximo de trabajadores que necesita** y **roles** requeridos.
- [ ] 🔧 **DECISIÓN 1 (confírmamela):** ¿un evento pide **un solo rol** o **varios a la vez**
      con nº por rol (ej. 3× Montaje + 1× Coordinador)?
      - Si es varios → añadir campo `plazasPorRol{rol:int}` al modelo `Evento` (hoy solo hay
        `rolAsignado` único). Migrar con compatibilidad hacia eventos existentes.
- [ ] Vista admin del evento: ver **cobertura en vivo** (aceptados X / máximo Y) y la lista de
      trabajadores que han aceptado.
- [ ] 🎯 El evento **se crea y sigue válido aunque no se llene** el máximo. Nada de bloqueos.

### 2B — Lado worker: feed de cartas (swipe)
- [ ] Nueva pantalla de **feed de eventos** en forma de pila de cartas.
      Cada carta muestra la info del evento (fecha, ubicación, roles, plazas, cobro/hora…).
- [ ] **Deslizar derecha = aceptar · izquierda = rechazar.** Al rechazar, esa carta no vuelve
      a salir. Al aceptar, se registra la respuesta del worker.
- [ ] Solo aparecen eventos **publicados**, **futuros** y que el worker **no haya respondido**
      todavía (y, si hay filtro por rol, que encajen con su rol).
- [ ] 🔧 **DECISIÓN 2 (confírmamela):** al deslizar derecha, ¿el worker **entra directo** al
      evento hasta llenar el máximo (por orden de llegada), o **solo se postula** y el admin
      **confirma** al final entre los que aceptaron?
      - Directo → más simple y automático; si se llena, la carta deja de ofrecerse.
      - Con confirmación → el admin tiene la última palabra (más profesional, recomendado).
- [ ] Modelo de datos nuevo para las respuestas. 🔧 A decidir según la DECISIÓN 2:
      - Opción simple: guardar aceptados/rechazados dentro del propio `Evento`.
      - Opción con postulaciones: colección nueva `respuestas` (o `postulaciones`)
        `{eventoId, trabajadorId, estado: aceptado|rechazado|confirmado, rol?, createdAt}`.
      - ⚠️ **Actualizar `firestore.rules`**: hoy el worker solo puede leer eventos donde ya
        está asignado. El feed necesita que pueda leer eventos **publicados** en los que **NO**
        está. Ampliar la regla de `eventos` y añadir reglas para la colección de respuestas
        (worker gestiona solo las suyas).
- [ ] Commit: `feat: feed de eventos tipo tinder (aceptar/rechazar por swipe)` → push.

> ⚠️ Antes de codificar esta fase, resuélveme la DECISIÓN 1 y la DECISIÓN 2. Ninguna línea
> de código de la Fase 2 se escribe hasta que yo las confirme.

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
