# 🐾 Patitas — Checklist de entrega

> **⏳ EN CURSO:** T1 y T2 — precargar datos del adoptante
> **✅ Hechas:** ninguna   ·   **⬜ Pendientes:** T3–T16
>
> **Cómo usar este archivo:** marca `[x]` cuando termines una tarea y mueve la línea
> "EN CURSO" a la siguiente. Cada tarea dice *qué hacer*, *en qué archivo* y *cuándo está lista*.

---

## 🎯 Qué hacer AHORA

**T1 + T2:** lograr que el formulario de adopción **no vuelva a pedir** los datos del usuario.
Es el requisito #1 del profesor y es un cambio pequeño. Al terminar, sigue con **T3**.

---

## ✅ MVP — lo que hay que entregar

### 🔴 P0 · Sin esto no se entrega

- [x] ⏳ **T1 · Precargar datos del adoptante** — `adoption_form_screen.dart`
  Leer `users/{uid}` y rellenar nombre, correo, teléfono y dirección. El usuario solo escribe el motivo.
  ✓ *Listo cuando:* el formulario abre con los campos ya rellenos.

- [x] ⏳ **T2 · Guardar cambios de datos** — `adoption_form_screen.dart`
  Si el usuario edita algún dato de contacto, guardarlo en `users/{uid}` (`merge:true`) para la próxima vez.
  ✓ *Listo cuando:* editar el teléfono lo deja persistido para la siguiente solicitud.

- [x] **T3 · Que el modelo lea el tipo** — `pet_model.dart`
  Agregar el campo `tipo` (Perro/Gato) leyéndolo desde Firestore en `fromFirestore`.
  ✓ *Listo cuando:* el modelo expone `pet.tipo`.

- [x] **T4 · Aplicar la preferencia al feed** — `feed_screen.dart`
  Leer `pref_tipo_$uid` y, si no es "Ambos", mostrar solo mascotas de ese tipo.
  ✓ *Listo cuando:* elegir "Perros" muestra solo perros.

### 🟠 P1 · Flujo sin callejones sin salida

- [ ] **T5 · Definir y aplicar quién publica** — `main.dart` / `profile_screen.dart` *(depende de Decisión A)*
  O se oculta el botón de publicar a adoptantes, o se da el panel de solicitudes a todo el que publica.
  ✓ *Listo cuando:* todo el que publica puede aprobar/rechazar sus solicitudes.

- [ ] **T6 · Evitar solicitudes duplicadas** — `adoption_form_screen.dart`
  Antes de crear la solicitud, revisar si ya existe una para esa mascota y ese usuario; si existe, abrir el chat actual.
  ✓ *Listo cuando:* dar swipe derecha dos veces no crea chats repetidos.

- [ ] **T7 · Mostrar el dueño real** — `adoption_form_screen.dart`
  Reemplazar el "Refugio Patitas" fijo del encabezado por el nombre real de `users/{orgId}`.
  ✓ *Listo cuando:* el encabezado muestra el nombre real del refugio/dueño.

### 🟡 P2 · Material Design 3 estricto (lo pide el profesor)

- [ ] **T8 · Sacar colores hardcodeados** — `pet_detail_screen.dart`, `feed_screen.dart`
  Cambiar colores crudos (naranjos, crema, azul/rosa) por roles de `colorScheme`.
  ✓ *Listo cuando:* el tema controla los colores y nada se rompe en dark mode.

- [ ] **T9 · Reemplazar API deprecada** — todo el proyecto
  Cambiar `.withOpacity(x)` por `.withValues(alpha: x)`.
  ✓ *Listo cuando:* `flutter analyze` no avisa por `withOpacity`.

- [ ] **T10 · Revisar tamaños y overflow** — `pet_detail_screen.dart`, `main.dart`
  Área táctil mínima 48dp; que las cajas de Edad/Peso/Tamaño no desborden en pantallas angostas.
  ✓ *Listo cuando:* no hay overflow en 360dp de ancho.

- [ ] **T11 · Unificar espaciados** — pantallas del flujo principal
  Dejar paddings y separaciones en múltiplos de 4/8.
  ✓ *Listo cuando:* los espaciados se ven consistentes.

### 🟢 P3 · Consistencia de datos

- [ ] **T12 · Marcar mascota como adoptada** — `org_panel_screen.dart` *(depende de Decisión B)*
  Botón "Marcar como adoptada" que pone `estado='adoptado'`.
  ✓ *Listo cuando:* una mascota adoptada sale del feed de forma definitiva.

- [ ] **T13 · Cerrar solicitudes competidoras** — `org_panel_screen.dart`
  Al aprobar a un adoptante, rechazar/cerrar las demás solicitudes pendientes de esa mascota.
  ✓ *Listo cuando:* aprobar a uno cierra automáticamente al resto.

- [ ] **T14 · Cuadrar contadores del perfil** — `profile_screen.dart`
  Verificar que "en proceso" y "adopciones" cuenten los estados correctos.
  ✓ *Listo cuando:* los números del perfil reflejan la realidad.

### 🔵 P4 · Gestión de publicaciones

- [ ] **T15 · Ver mis publicaciones** — `my_publications_screen.dart` (nuevo), `profile_screen.dart`
  Apartado "Mis publicaciones" en el perfil que lista las mascotas con `orgId == miUid`; visible para todos los usuarios.
  ✓ *Listo cuando:* desde el perfil abro la lista y veo mis mascotas publicadas.

- [ ] **T16 · Editar una publicación** — `publish_pet_screen.dart`, `my_publications_screen.dart`
  Reutilizar el formulario de publicar con un `petId` opcional: si viene, precarga los datos y actualiza el mismo documento en vez de crear uno nuevo.
  ✓ *Listo cuando:* edito una mascota y sus datos cambian sin duplicarla; publicar nuevo sigue igual.

---

## 💡 Extras — solo si sobra tiempo (no bloquean la entrega)

- [ ] **E1** · Pantalla "Lista de Favoritos" (los favoritos ya se guardan, falta verlos).
- [ ] **E2** · Mover favoritos a Firestore para sincronizar entre dispositivos.
- [ ] **E3** · Filtrar el feed también por raza y edad.
- [ ] **E4** · Notificaciones (colección `notificaciones`).
- [ ] **E5** · Distancia real por GPS (hoy está fija en "2.5 km").
- [ ] **E6** · Modo oscuro.
- [ ] **E7** · Limpieza: borrar `mock_auth_service.dart` y `mockUserProfile` (código muerto).
- [ ] **E8** · Endurecer reglas de seguridad de Firestore/Storage.

---

## ❓ Decisiones que faltan resolver

### Decisión A — ¿Quién puede publicar mascotas?

Hoy publica cualquiera, pero solo el rol "organización" puede aprobar solicitudes. Si una persona
natural publica, su chat nunca se desbloquea. → Hay que elegir: solo refugios, o también personas
(y en ese caso darles el panel de solicitudes). **Esto define T5.**

### Decisión B — ¿Qué pasa con la publicación al aceptar una adopción?

Hoy al aprobar, la mascota queda "en proceso" (sale del feed) pero nunca llega a "adoptada", y las
otras solicitudes quedan colgadas. → Recomendado: agregar un botón manual "Marcar como adoptada"
que cierre todo. **Esto define T12 y T13.**

---

## 📌 Apéndice — estado actual (para retomar rápido)

**Ya funciona:** login (email + Google con roles), registro, feed tipo Tinder, diálogo de
preferencia una sola vez + botón de filtro, formulario de adopción que crea solicitud + chat
bloqueado, **chat completo** (se desbloquea al aprobar desde el panel), perfil que lee/escribe en
Firestore, publicar mascota con foto, favoritos locales.

**Roto / pendiente:** el formulario re-pide los datos (T1-T2), la preferencia no filtra el feed
(T3-T4), persona natural no puede aprobar sus solicitudes (T5), nunca se marca "adoptado" (T12-T13),
y quedan colores fuera del tema MD3 (T8).
```
