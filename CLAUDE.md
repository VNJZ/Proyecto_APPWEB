# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proyecto

**Patitas** es una app móvil Android de adopción de mascotas para Chile (TEL335, UTFSM). Conecta tres actores en una sola plataforma: adoptante, animal y rescatista/fundación. El core es un sistema de swipe ordenado por compatibilidad de estilo de vida + matching verificado que habilita el chat solo tras aprobación del rescatista.

## Commands

```bash
# Correr en dispositivo/emulador conectado
flutter run

# Analizar errores de lint
flutter analyze

# Correr todos los tests
flutter test

# Correr un test específico
flutter test test/widget_test.dart

# Obtener dependencias
flutter pub get
```

## Stack tecnológico

- **Flutter** — Android únicamente, API 24 mínimo / API 34 target
- **Firebase Auth** — autenticación de usuarios
- **Cloud Firestore** — base de datos en tiempo real
- **Firebase Storage** — imágenes de mascotas
- **Firebase Cloud Messaging** — notificaciones push
- **Sin backend propio** — todo directo con Firebase (sin Node.js/Express ni PostgreSQL)

### Paquetes principales

| Paquete | Uso |
|---|---|
| `flutter_card_swiper` | Swipe de tarjetas de mascotas |
| `flutter_riverpod` | State management |
| `go_router` | Navegación |
| `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` | Firebase |
| `geolocator` | Distancia a la fundación |
| `image_picker` | Fotos de mascotas |
| `flutter_chat_ui` | Chat entre adoptante y rescatista |
| `dio` | HTTP client |

## Arquitectura

### Estructura de carpetas (Feature-first)

```
lib/
  features/
    feed/          # Swipe de mascotas
    adoption/      # Solicitud de adopción
    chat/          # Chat adoptante ↔ rescatista
    auth/          # Login
    profile/       # Perfil de usuario
  models/          # Modelos de datos compartidos
  core/            # Router, theme, providers globales
```

### State management

Riverpod con `AsyncNotifier`. No usar `setState` salvo para estado local puramente de UI (ej. animaciones).

### Navegación

`go_router` para todas las rutas. El `NavigationBar` (Material 3) en el root tiene tres destinos: Feed, Mensajes, Perfil.

### Flujo principal

1. Usuario hace swipe derecho → se envía solicitud de adopción a Firestore
2. Rescatista aprueba/rechaza → FCM envía notificación al adoptante
3. Si aprobado → `matchAprobado = true` en Firestore → chat se desbloquea
4. Si el animal ya fue adoptado → desaparece del feed en tiempo real (Firestore stream)

### Estado actual del código

El código existente en `lib/` usa mock data hardcodeada y `setState`. Al migrar a Firebase:
- `uidActual` (`chat_individual.dart:20`) → `FirebaseAuth.instance.currentUser!.uid`
- `chatsMock` / `mensajesMock` → streams de Firestore
- `imageUrls` en `PetModel` → URLs de Firebase Storage

### Referencias de diseño

Las imágenes de referencia visual están en `/design_reference/`.

## Sistema de diseño — Material Design 3

Seguir **todos** los estándares de Material You:

- `NavigationBar` (NO `BottomNavigationBar` que es MD2)
- `FilledButton`, `OutlinedButton`, `TextButton` (NO `ElevatedButton` clásico)
- `CardTheme` con `shape` redondeado
- Tipografía via `TextTheme` de Material 3
- Componentes nativos MD3: `SnackBar`, `Dialog`, `BottomSheet`, etc.

### Paleta de colores

Seed color principal: `#1D9E75` (verde). MD3 genera toda la paleta automáticamente — **nunca hardcodear colores directamente**.

```dart
// Correcto
Theme.of(context).colorScheme.primary

// Incorrecto
Color(0xFF1D9E75)
```

Los colores rosa `#D4537E` y naranja `#F2A62F` pueden usarse como `secondary` o `tertiary` seed según convenga.

## Convenciones de código

- **Arquitectura**: Feature-first
- **Nombrado**: `camelCase` para variables, `PascalCase` para clases
- **Idioma**: código en inglés, comentarios en español

## Requerimientos funcionales

1. Login (Firebase Auth)
2. Tarjetas de mascotas con like/descartar (swipe)
3. Envío de solicitud de adopción
4. Chat interno entre adoptante y publicador (solo tras match aprobado)
5. Notificación push cuando una solicitud es aprobada o rechazada

## Requerimientos no funcionales

- Validación en tiempo real (Firestore streams)
- Fotos de mascotas (Firebase Storage + `image_picker`)
- Formulario de solicitud de adopción
- Manejo de error sin internet
- Notificaciones push (FCM)
- Hardware requerido: GPS, cámara/galería, conectividad WiFi, almacenamiento
