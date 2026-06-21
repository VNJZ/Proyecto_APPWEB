# 🐾 Patitas — Checklist de entrega

> ⏳ **EN CURSO:** T1 y T2 — precargar datos del adoptante  
> ✅ Hechas: ninguna · ⬜ Pendientes: T3–T14

## Cómo usar este archivo

Marca `[x]` cuando termines una tarea y mueve la línea **"EN CURSO"** a la siguiente.

Cada tarea indica:
- Qué hacer
- En qué archivo
- Cuándo se considera terminada

---

# 🎯 Qué hacer AHORA

### T1 + T2: lograr que el formulario de adopción no vuelva a pedir los datos del usuario

Es el requisito #1 del profesor y es un cambio pequeño.

➡️ Al terminar, sigue con **T3**.

---

# ✅ MVP — lo que hay que entregar

## 🔴 P0 · Sin esto no se entrega

- [x] **T1 · Precargar datos del adoptante**
  - **Archivo:** `adoption_form_screen.dart`
  - Leer `users/{uid}` y rellenar nombre, correo, teléfono y dirección.
  - El usuario solo escribe el motivo.
  - **✓ Listo cuando:** el formulario abre con los campos ya rellenos.

- [x] **T2 · Guardar cambios de datos**
  - **Archivo:** `adoption_form_screen.dart`
  - Si el usuario edita algún dato de contacto, guardarlo en `users/{uid}` (`merge: true`) para la próxima vez.
  - **✓ Listo cuando:** editar el teléfono lo deja persistido para la siguiente solicitud.

- [x] **T3 · Que el modelo lea el tipo**
  - **Archivo:** `pet_model.dart`
  - Agregar el campo `tipo` (Perro/Gato) leyéndolo desde Firestore en `fromFirestore`.
  - **✓ Listo cuando:** el modelo expone `pet.tipo`.

- [x] **T4 · Aplicar la preferencia al feed**
  - **Archivo:** `feed_screen.dart`
  - Leer `pref_tipo_$uid` y, si no es `"Ambos"`, mostrar solo mascotas de ese tipo.
  - **✓ Listo cuando:** elegir `"Perros"` muestra solo perros.

---

## 🟠 P1 · Flujo sin callejones sin salida

- [ ] **T5 · Definir y aplicar quién publica**
  - **Archivos:** `main.dart` / `profile_screen.dart`
  - *(Depende de Decisión A)*
  - O se oculta el botón de publicar a adoptantes, o se da el panel de solicitudes a todo el que publica.
  - **✓ Listo cuando:** todo el que publica puede aprobar/rechazar sus solicitudes.

- [ ] **T6 · Evitar solicitudes duplicadas**
  - **Archivo:** `adoption_form_screen.dart`
  - Antes de crear la solicitud, revisar si ya existe una para esa mascota y ese usuario.
  - Si existe, abrir el chat actual.
  - **✓ Listo cuando:** dar swipe derecha dos veces no crea chats repetidos.

- [ ] **T7 · Mostrar el dueño real**
  - **Archivo:** `adoption_form_screen.dart`
  - Reemplazar el `"Refugio Patitas"` fijo del encabezado por el nombre real de `users/{orgId}`.
  - **✓ Listo cuando:** el encabezado muestra el nombre real del refugio/dueño.

---

## 🟡 P2 · Material Design 3 estricto (lo pide el profesor)

- [ ] **T8 · Sacar colores hardcodeados**
  - **Archivos:** `pet_detail_screen.dart`, `feed_screen.dart`
  - Cambiar colores crudos (naranjos, crema, azul/rosa) por roles de `colorScheme`.
  - **✓ Listo cuando:** el tema controla los colores y nada se rompe en dark mode.

- [ ] **T9 · Reemplazar API deprecada**
  - **Archivo:** todo el proyecto
  - Cambiar `.withOpacity(x)` por `.withValues(alpha: x)`.
  - **✓ Listo cuando:** `flutter analyze` no avisa por `withOpacity`.

- [ ] **T10 · Revisar tamaños y overflow**
  - **Archivos:** `pet_detail_screen.dart`, `main.dart`
  - Área táctil mínima de 48dp.
  - Que las cajas de Edad/Peso/Tamaño no desborden en pantallas angostas.
  - **✓ Listo cuando:** no hay overflow en 360dp de ancho.

- [ ] **T11 · Unificar espaciados**
  - **Archivos:** pantallas del flujo principal
  - Dejar paddings y separaciones en múltiplos de 4/8.
  - **✓ Listo cuando:** los espaciados se ven consistentes.

---

## 🟢 P3 · Consistencia de datos

- [ ] **T12 · Marcar mascota como adoptada**
  - **Archivo:** `org_panel_screen.dart`
  - *(Depende de Decisión B)*
  - Botón **"Marcar como adoptada"** que pone `estado = 'adoptado'`.
  - **✓ Listo cuando:** una mascota adoptada sale del feed de forma definitiva.

- [ ] **T13 · Cerrar solicitudes competidoras**
  - **Archivo:** `org_panel_screen.dart`
  - Al aprobar a un adoptante, rechazar/cerrar las demás solicitudes pendientes de esa mascota.
  - **✓ Listo cuando:** aprobar a uno cierra automáticamente al resto.

- [ ] **T14 · Cuadrar contadores del perfil**
  - **Archivo:** `profile_screen.dart`
  - Verificar que `"en proceso"` y `"adopciones"` cuenten los estados correctos.
  - **✓ Listo cuando:** los números del perfil reflejan la realidad.

---

# 💡 Extras — solo si sobra tiempo

> No bloquean la entrega.

- [ ] **E1 · Pantalla "Lista de Favoritos"**
  - Los favoritos ya se guardan; falta mostrarlos.

- [ ] **E2 · Mover favoritos a Firestore**
  - Para sincronizar entre dispositivos.

- [ ] **E3 · Filtrar el feed también por raza y edad**

- [ ] **E4 · Notificaciones**
  - Colección `notificaciones`.

- [ ] **E5 · Distancia real por GPS**
  - Hoy está fija en `"2.5 km"`.

- [ ] **E6 · Modo oscuro**

- [ ] **E7 · Limpieza**
  - Borrar `mock_auth_service.dart` y `mockUserProfile` (código muerto).

- [ ] **E8 · Endurecer reglas de seguridad**
  - Firestore y Storage.

---

# ❓ Decisiones que faltan resolver

## Decisión A — ¿Quién puede publicar mascotas?

Hoy publica cualquiera, pero solo el rol `"organización"` puede aprobar solicitudes.

Si una persona natural publica, su chat nunca se desbloquea.

### Opciones

1. Solo refugios pueden publicar.
2. Personas naturales también pueden publicar y reciben panel de solicitudes.

➡️ Esto define **T5**.

---

## Decisión B — ¿Qué pasa con la publicación al aceptar una adopción?

Hoy, al aprobar:

- La mascota queda `"en proceso"` (sale del feed).
- Nunca llega a `"adoptada"`.
- Las otras solicitudes quedan colgadas.

### Recomendación

Agregar un botón manual:

**"Marcar como adoptada"**

que cierre todo el proceso.

➡️ Esto define **T12** y **T13**.

---

# 📌 Apéndice — estado actual

## ✅ Ya funciona

- Login (email + Google con roles)
- Registro
- Feed tipo Tinder
- Diálogo de preferencia una sola vez + botón de filtro
- Formulario de adopción que crea solicitud + chat bloqueado
- Chat completo (se desbloquea al aprobar desde el panel)
- Perfil que lee/escribe en Firestore
- Publicar mascota con foto
- Favoritos locales

## ⚠️ Roto / pendiente

- El formulario vuelve a pedir los datos (**T1–T2**)
- La preferencia no filtra el feed (**T3–T4**)
- Persona natural no puede aprobar sus solicitudes (**T5**)
- Nunca se marca `"adoptado"` (**T12–T13**)
- Quedan colores fuera del tema MD3 (**T8**)
