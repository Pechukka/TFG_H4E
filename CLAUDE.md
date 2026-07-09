# CLAUDE.md — Guía de trabajo para Claude Code

> Lee este archivo entero antes de tocar nada. Es la fuente de verdad del proyecto.
> Si algo de aquí choca con lo que te pido en un mensaje, avísame antes de seguir.

---

## 1. Qué es este proyecto

**Hands4Events (H4E)** es una plataforma de gestión de personal para eventos.
Es mi TFG del grado superior de DAM, pero el objetivo real ahora es **convertirlo en un
producto vendible a la empresa Hands for Events** (empresa real de montaje/desmontaje y
personal de eventos). Voy a presentárselo como propuesta: app + mantenimiento de pago.

Por eso todo lo que hagas tiene un doble objetivo:
1. Que **funcione y no falle** (es una demo que voy a enseñar a un cliente real).
2. Que se vea **profesional y creíble**, sin humo ni funciones a medias.

Hoy la empresa gestiona todo por WhatsApp (grupos, mensajes preguntando disponibilidad).
Esta app centraliza eso: disponibilidad, eventos, fichajes por ubicación, chat por evento y nóminas.

---

## 2. Cómo trabajo yo (reglas de estilo — OBLIGATORIAS)

- **Código sencillo, nivel estudiante. Nada de sobre-ingeniería.** Si dudas entre una
  solución "elegante y abstracta" y una "directa y legible", elige la directa.
- **Variables, funciones y comentarios EN ESPAÑOL.** Igual que el código existente
  (`trabajadorId`, `guardarDisponibilidad`, `fondoCard`, etc.). No mezcles inglés.
- **Comenta lo justo pero claro**, explicando el *por qué*, no el *qué*.
- Cuando un cambio requiera que yo ajuste algo a mano (una key, un valor, una decisión),
  **déjalo marcado bien visible** con un comentario:
  `// 🔧 AJUSTAR: aquí va tu... / cambia esto según...`
- **No añadas dependencias nuevas a `pubspec.yaml` sin preguntarme primero.**
- **Respuestas y explicaciones densas y al grano.** No me escribas ensayos.
- Nada de ZIPs ni de generar el código en un chat aparte: trabajas directo sobre los archivos.

---

## 3. Stack y arquitectura (lo que hay, respétalo)

- **Flutter** (Dart SDK `>=3.2.0 <4.0.0`), un **único código base** para dos experiencias:
  - **Admin → panel WEB** (`AdminShell`, se activa cuando `kIsWeb && rol == 'admin'`).
  - **Worker → app MÓVIL** (`MainScaffold`, con `BottomNavigationBar`).
  - El reparto se decide en `lib/main.dart` → `AuthWrapper`.
- **Firebase**: Auth, Cloud Firestore, Storage, Cloud Messaging (FCM).
  - ⚠️ **FCM solo funciona en móvil.** En web está desactivado a propósito (falta VAPID).
    No intentes activar push en web sin avisarme.
- **Estado**: `provider` (ChangeNotifier). Un provider por dominio, ya registrados en `main.dart`.
- **Cloud Functions** (`functions/index.js`, Node): de momento solo `onWorkerDeleted`
  (al borrar un usuario de Firestore lo borra de Auth y lo saca de sus eventos).

### Estructura de carpetas (`lib/`)
```
core/       constantes, roles, theme, traducciones, firebase_options
models/     modelos de datos (Firestore <-> Dart)
services/   acceso a Firestore/Storage/FCM (la lógica de datos vive aquí)
providers/  estado + puente entre UI y services
screens/    pantallas   (worker: dashboard, calendario, eventos, fichaje, nominas, perfil, chat)
            (admin:  screens/admin/** -> workers, eventos, nominas)
widgets/    componentes reutilizables (botones, campos, modales)
```
**Patrón de capas:** `screen` → `provider` → `service` → Firestore. No metas llamadas a
Firestore directamente en las pantallas; pasa por el service correspondiente.

### Convención Firestore IMPORTANTE (no la rompas)
Para evitar tener que crear índices compuestos en Firestore, el proyecto **filtra y ordena
en Dart**, no en la query. Ejemplo real: se consulta `where('trabajadorId', isEqualTo: uid)`
y luego se filtra por fecha con `.where(...)` de Dart. **Mantén ese patrón.** Si en algún
punto de verdad hace falta un índice, márcalo con `// 🔧 AJUSTAR: requiere índice Firestore`.

---

## 4. Modelo de datos (colecciones Firestore)

Nombres centralizados en `lib/core/constants.dart` (`AppConstants.col...`). Úsalos siempre.

- **`users`** → `nombre, email, telefono?, direccion?, idioma, rol ('worker'|'admin'),
  avatarUrl?, createdAt, fechaContratacion?, notifActivadas, debeReiniciarPassword`
- **`eventos`** → `titulo, fechaInicio, fechaFin, ubicacion, descripcion, cobroPorHora,
  rolAsignado, trabajadoresIds[], trabajadoresRoles{uid: rol}`
- **`disponibilidad`** → `trabajadorId, fecha, horaInicio{hour,minute}, horaFin{hour,minute},
  aplicarRecurrente, diaSemana?, createdAt`
  ⚠️ **En proceso de jubilación:** la Fase 2 la sustituye por respuestas del worker a eventos
  (feed tipo Tinder). Ver ROADMAP · Fase 2. No construyas cosas nuevas sobre esta colección.
- **`fichajes`** → entrada/salida por ubicación (GPS) de cada worker en un evento
- **`mensajes`** → chat de grupo por evento
- **`nominas`** → nómina calculada por trabajador/mes, guardada para que la vea el worker
- Storage: `nominas/`, `chat_images/`

**Roles de evento** (`lib/core/roles.dart`): `H4ndMontaje` (8.0€/h), `H4ndDesmontaje`
(7.5€/h), `Coordinador` (10.0€/h), `Runner` (9.0€/h). Si tocas tarifas, hazlo solo aquí.

---

## 5. Identidad visual (respétala, no la reinventes)

Todo el color sale de `lib/core/theme.dart` (`AppTheme`). **Usa siempre esas constantes,
nunca colores a pelo.**
- Tema **oscuro** corporativo, acento **verde lima neón** `verdeNeon = #84CC16`.
- Fondos: `fondoPrincipal #0A0F0A`, `fondoCard #1A2218`, `fondoInput #12180F`.
- Material Design clásico (no Material 3).

El panel admin hoy es **funcional pero muy soso** (se hizo rápido). Se puede pulir, pero:
**minimalista y funcional por encima de lo bonito.** Sin decoración excesiva ni animaciones
de más. Limpio, con buena jerarquía y espaciado. Nada de cambiar la paleta.

---

## 6. Flujo de trabajo con Git (haz esto en cada fase)

Repo: `github.com/Pechukka/TFG_H4E` · rama base: `main`.

- Trabaja **una fase del ROADMAP.md a la vez**, en orden.
- Para cada fase:
  1. Crea una rama `fase-N-nombre-corto` desde `main`.
  2. Implementa **solo** lo de esa fase.
  3. Al terminar, ejecuta `flutter analyze` y arregla lo que salga.
  4. Haz **commit** con mensaje claro estilo convencional
     (`feat:`, `fix:`, `chore:`, `refactor:` + descripción en español).
  5. **Push** de la rama y dime que está lista para que yo la revise/mergee.
     (Si te digo que mergees tú a `main`, hazlo; por defecto NO mergees sin avisar.)
- Marca en `ROADMAP.md` la fase como completada (`[x]`) al cerrarla.
- **Nunca** hagas `force push`, ni reescribas historia, ni toques `main` directamente.

---

## 7. Cómo verificar antes de dar algo por hecho

- `flutter pub get` tras cualquier cambio en `pubspec.yaml`.
- `flutter analyze` **debe salir limpio** (o solo con warnings que me expliques).
- Comprueba que **no rompes ninguna de las dos experiencias**: piensa siempre
  "¿esto sigue funcionando en el panel web admin Y en la app móvil worker?".
- No borres funcionalidad existente para "simplificar" sin preguntarme.

---

## 8. Seguridad — cosas que hay que arreglar (NO las ignores)

1. **API key de Google Maps hardcodeada** en `lib/core/constants.dart`
   (`googleMapsApiKey`). El repo es público → hay que sacarla del código o, mínimo,
   restringirla por app/dominio en Google Cloud. Se aborda en la Fase 0.
2. **No hay `firestore.rules` ni `storage.rules`** en el repo. Para un producto real hay
   que definir reglas por rol (worker solo ve/edita lo suyo; admin gestiona todo).
   Se aborda en la Fase 0.
3. No subas nunca secretos nuevos al repo. Si algo es sensible, va en variables/config
   fuera de git y lo marcas con `// 🔧 AJUSTAR`.

---

## 9. Qué NO tocar sin permiso

- `firebase_options.dart`, `google-services.json`, IDs de proyecto Firebase.
- Versiones de paquetes Firebase en `pubspec.yaml` (todos deben ir en el mismo major
  de FlutterFire; ya está avisado en el propio archivo).
- ⚠️ El sistema de **disponibilidad** (`disponibilidad`, `DisponibilidadService`,
  `AdminService.tieneDisponibilidad`, `modal_disponibilidad`, `calendario_screen`) **se sustituye
  entero en la Fase 2** por un feed de eventos tipo Tinder. No lo borres ni lo modifiques por tu
  cuenta antes de llegar a esa fase y de que yo confirme las decisiones marcadas allí.
- La carpeta `functions/node_modules/` ni nada autogenerado.
