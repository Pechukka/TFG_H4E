# Hands4Events (H4E)

Plataforma de **gestión de personal para eventos**: centraliza disponibilidad, eventos,
fichajes por ubicación (GPS), chat por evento y nóminas. Nace como TFG del grado superior
de DAM y está pensada como producto real para una empresa de montaje/desmontaje y personal
de eventos que hoy gestiona todo por WhatsApp.

Un **único código base Flutter** sirve dos experiencias:

- **Admin → panel web** (`AdminShell`): se activa cuando la app corre en web y el usuario
  tiene rol `admin`. Gestiona trabajadores, eventos y nóminas.
- **Worker → app móvil** (`MainScaffold`): navegación inferior con dashboard, calendario,
  eventos, fichaje, nóminas, perfil y chat.

El reparto entre ambas se decide en [lib/main.dart](lib/main.dart) → `AuthWrapper`.

---

## Stack

- **Flutter** (Dart SDK `>=3.2.0 <4.0.0`).
- **Firebase**: Authentication, Cloud Firestore, Storage y Cloud Messaging (FCM).
  - ⚠️ **FCM solo funciona en móvil.** En web está desactivado a propósito (falta VAPID).
- **Estado**: `provider` (ChangeNotifier), un provider por dominio.
- **Cloud Functions** (`functions/index.js`, Node): `onWorkerDeleted` (al borrar un usuario
  de Firestore lo borra de Auth y lo saca de sus eventos).
- **Mapas**: `flutter_map` + OpenStreetMap para la vista; la API de Google Maps
  (geocoding / places) se usa solo para búsqueda de direcciones.

---

## Estructura del proyecto (`lib/`)

```
core/       constantes, roles, theme, traducciones, firebase_options
models/     modelos de datos (Firestore <-> Dart)
services/   acceso a Firestore/Storage/FCM (la lógica de datos vive aquí)
providers/  estado + puente entre UI y services
screens/    pantallas worker (dashboard, calendario, eventos, fichaje, nominas, perfil, chat)
            y admin (screens/admin/** -> workers, eventos, nominas)
widgets/    componentes reutilizables (botones, campos, modales)
```

**Patrón de capas:** `screen` → `provider` → `service` → Firestore. Las pantallas no llaman
a Firestore directamente.

---

## Puesta en marcha

### Requisitos

- Flutter SDK instalado (`flutter --version`).
- Acceso al proyecto Firebase `hands4events-cd714` (los ficheros `firebase_options.dart` y
  `google-services.json` ya están en el repo).

### Instalar dependencias

```bash
flutter pub get
```

### 🔧 Configurar la API key de Google Maps

La key **no está en el código** (se sacó por seguridad). Hay que aportarla al ejecutar/compilar:

- **En Dart** (búsqueda de direcciones), por `--dart-define`:

  ```bash
  flutter run   --dart-define=GOOGLE_MAPS_API_KEY=TU_KEY
  flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=TU_KEY
  ```

- **En Android nativo**, añade en `android/local.properties` (fichero no versionado):

  ```properties
  mapsApiKey=TU_KEY
  ```

Genera una key **nueva y restringida** por app/dominio en Google Cloud (la antigua está
comprometida por haber estado en el repo público).

### Arrancar cada experiencia

- **Worker (app móvil):** en un emulador/dispositivo Android:

  ```bash
  flutter run --dart-define=GOOGLE_MAPS_API_KEY=TU_KEY
  ```

- **Admin (panel web):** en navegador (inicia sesión con un usuario de rol `admin`):

  ```bash
  flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=TU_KEY
  ```

---

## Seguridad

- **Reglas por rol** en [firestore.rules](firestore.rules) y [storage.rules](storage.rules):
  el worker solo ve/edita lo suyo; el admin gestiona todo. Desplegar con:

  ```bash
  firebase deploy --only firestore:rules,storage
  ```

- La API key de Google Maps se mantiene fuera del control de versiones (ver arriba).

---

## Verificación

Tras cualquier cambio:

```bash
flutter pub get      # si tocaste pubspec.yaml
flutter analyze      # debe salir limpio
```
