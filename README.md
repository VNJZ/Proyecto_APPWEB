# Patitas - Checklist de entrega

> **EN CURSO:** T8-T11 - ajustes de Material Design 3
> **Hechas:** T1-T7, T12-T14
> **Pendientes:** T8-T11, T15-T16
>
> Marca `[x]` cuando una tarea quede realmente lista en código. Este archivo ya fue actualizado según el avance implementado en este repositorio.

---

## Decisiones resueltas

### Decision A - Quien puede publicar mascotas

Se mantiene que cualquier usuario autenticado puede publicar mascotas.
Tambien se habilito que una persona natural pueda abrir el panel de sus publicaciones y aprobar o rechazar solicitudes sobre mascotas con `orgId == su uid`.

### Decision B - Que pasa con la publicacion al aceptar una adopcion

Se agrego el flujo recomendado:

- Al aprobar una solicitud, la mascota pasa a `en_proceso` y se desbloquea ese chat.
- Las otras solicitudes pendientes de esa mascota se cierran automaticamente.
- Desde el panel aparece el boton **Marcar adoptada** para cerrar el caso y dejar la mascota en `adoptado`.

---

## Estado actual

**Ya funciona:** login (email + Google con roles), registro, feed tipo Tinder, dialogo de preferencia una sola vez + boton de filtro, formulario de adopcion con datos precargados, persistencia de datos del adoptante, bloqueo de solicitudes duplicadas, chat completo, perfil conectado a Firestore, publicar mascota con foto, panel para publicadores naturales y organizaciones, cierre automatico de solicitudes competidoras, boton para marcar mascota como adoptada, favoritos locales.

**Pendiente principal:** colores hardcodeados y ajustes MD3 (`T8-T11`), mas la gestion de publicaciones propias (`T15-T16`).

---

## MVP - lo que hay que entregar

### P0 - Sin esto no se entrega

- [x] **T1 - Precargar datos del adoptante** - `adoption_form_screen.dart`
  Leer `users/{uid}` y rellenar nombre, correo, telefono y direccion. El usuario solo escribe el motivo.
  Listo cuando el formulario abre con los campos ya rellenos.

- [x] **T2 - Guardar cambios de datos** - `adoption_form_screen.dart`
  Si el usuario edita algun dato de contacto, guardarlo en `users/{uid}` con `merge:true` para la proxima vez.
  Listo cuando editar el telefono lo deja persistido para la siguiente solicitud.

- [x] **T3 - Que el modelo lea el tipo** - `pet_model.dart`
  Agregar el campo `tipo` (Perro/Gato) leyendolo desde Firestore en `fromFirestore`.
  Listo cuando el modelo expone `pet.tipo`.

- [x] **T4 - Aplicar la preferencia al feed** - `feed_screen.dart`
  Leer `pref_tipo_$uid` y, si no es `Ambos`, mostrar solo mascotas de ese tipo.
  Listo cuando elegir `Perros` muestra solo perros.

### P1 - Flujo sin callejones sin salida

- [x] **T5 - Definir y aplicar quien publica** - `profile_screen.dart`, `org_panel_screen.dart`
  Se opto por permitir que cualquier publicador gestione solicitudes de sus mascotas.
  Listo cuando todo el que publica puede aprobar o rechazar sus solicitudes.

- [x] **T6 - Evitar solicitudes duplicadas** - `adoption_form_screen.dart`
  Antes de crear la solicitud, revisar si ya existe una para esa mascota y ese usuario; si existe, abrir el chat actual.
  Listo cuando dar swipe derecha dos veces no crea chats repetidos.

- [x] **T7 - Mostrar el dueno real** - `adoption_form_screen.dart`
  Reemplazar el texto fijo del encabezado por el nombre real de `users/{orgId}`.
  Listo cuando el encabezado muestra el nombre real del refugio o publicador.

### P2 - Material Design 3 estricto

- [ ] **T8 - Sacar colores hardcodeados** - `pet_detail_screen.dart`, `feed_screen.dart`
  Cambiar colores crudos por roles de `colorScheme`.
  Listo cuando el tema controla los colores y nada se rompe en dark mode.

- [ ] **T9 - Reemplazar API deprecada** - todo el proyecto
  Cambiar `.withOpacity(x)` por `.withValues(alpha: x)`.
  Listo cuando no queden usos de `withOpacity`.

- [ ] **T10 - Revisar tamanos y overflow** - `pet_detail_screen.dart`, `main.dart`
  Area tactil minima 48dp; que las cajas de Edad/Peso/Tamano no desborden en pantallas angostas.
  Listo cuando no hay overflow en 360dp de ancho.

- [ ] **T11 - Unificar espaciados** - pantallas del flujo principal
  Dejar paddings y separaciones en multiplos de 4/8.
  Listo cuando los espaciados se ven consistentes.

### P3 - Consistencia de datos

- [x] **T12 - Marcar mascota como adoptada** - `org_panel_screen.dart`
  Boton `Marcar adoptada` que pone `estado='adoptado'`.
  Listo cuando una mascota adoptada sale del feed de forma definitiva.

- [x] **T13 - Cerrar solicitudes competidoras** - `org_panel_screen.dart`
  Al aprobar a un adoptante, rechazar o cerrar las demas solicitudes pendientes de esa mascota.
  Listo cuando aprobar a uno cierra automaticamente al resto.

- [x] **T14 - Cuadrar contadores del perfil** - `profile_screen.dart`
  Ajustar los contadores del perfil a los estados reales del flujo.
  Listo cuando `En proceso` y `Adopciones` reflejan mejor el avance de cada caso.

### P4 - Gestion de publicaciones

- [ ] **T15 - Ver mis publicaciones** - `my_publications_screen.dart`, `profile_screen.dart`
  Apartado `Mis publicaciones` en el perfil que liste las mascotas con `orgId == miUid`; visible para todos los usuarios.
  Listo cuando desde el perfil abro la lista y veo mis mascotas publicadas.

- [ ] **T16 - Editar una publicacion** - `publish_pet_screen.dart`, `my_publications_screen.dart`
  Reutilizar el formulario de publicar con un `petId` opcional: si viene, precarga los datos y actualiza el mismo documento en vez de crear uno nuevo.
  Listo cuando edito una mascota y sus datos cambian sin duplicarla; publicar nuevo sigue igual.

---

## Extras - solo si sobra tiempo

- [ ] **E1** - Pantalla `Lista de Favoritos`.
- [ ] **E2** - Mover favoritos a Firestore para sincronizar entre dispositivos.
- [ ] **E3** - Filtrar el feed tambien por raza y edad.
- [ ] **E4** - Notificaciones con coleccion `notificaciones`.
- [ ] **E5** - Distancia real por GPS.
- [ ] **E6** - Modo oscuro.
- [ ] **E7** - Limpieza: borrar `mock_auth_service.dart` y `mockUserProfile`.
- [ ] **E8** - Endurecer reglas de seguridad de Firestore y Storage.
