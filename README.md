# Logix OptiFlow — Flutter

Cliente Flutter del mismo producto que la app Android [Logix-OptiFlow-Mobile](https://github.com/BL-App-Movil-1ACC0238-2620-4951/Logix-OptiFlow-Mobile).

Incluye las dos experiencias:

- **Paciente:** acceso, inicio, búsqueda de ópticas, reserva de citas, pedidos, catálogo, receta, historial, notificaciones y perfil.
- **Personal clínico:** acceso con cuenta real de optometrista, asesor de ventas, técnico o administrador. La navegación y los enlaces directos se restringen según el rol devuelto por el backend.

## Backend

| Entorno | Base URL |
|--------|-----------|
| Producción (Render) | `https://logix-optiflow-back-end.onrender.com/api/v1/` |
| Local | pásala con `--dart-define` |

Swagger: [https://logix-optiflow-back-end.onrender.com/swagger-ui/index.html](https://logix-optiflow-back-end.onrender.com/swagger-ui/index.html)

La primera petición a Render puede tardar cerca de un minuto si el servicio está dormido.

Cuenta de demostración:

| Campo | Valor |
|--------|--------|
| Correo | `demo.paciente@optiflow.pe` |
| Contraseña | `Optiflow123` |

## Ejecutar

```powershell
flutter pub get
flutter run
```

Backend local:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1/
```

En un celular físico usa la IP de tu PC en lugar de `10.0.2.2`. En escritorio o web usa `http://localhost:8080/api/v1/`. También se acepta la URL del servidor sin `/api/v1`: el cliente agrega el prefijo una sola vez.

El catálogo de monturas, el inventario y la operación clínica usan los mismos datos de prototipo que la app Android cuando el API no los expone. Login, ópticas, horarios y reservas sí salen del backend.

## Migración por bloques — bloque 1

- Login de pacientes y personal con `POST /api/v1/auth/tokens`, seguido de la carga de su perfil.
- Registro de pacientes y login posterior. Las cuentas del personal las crea el administrador desde las herramientas de gestión.
- Sesión persistente con rol, token, vencimiento y óptica del personal. Las solicitudes autenticadas envían `Authorization: Bearer <token>`.
- Al recibir un 401 autenticado se limpia la sesión y se vuelve al acceso. Un 403 muestra un error de permisos sin cerrar la sesión.
- Rutas, inicio, barra inferior y herramientas disponibles según los permisos del rol.

| Rol | Secciones del personal |
|-----|-----------------------|
| Optometrista | Agenda, pacientes y atención clínica |
| Asesor de ventas | Agenda, pacientes, consulta de stock, cotizaciones y ventas |
| Técnico | Producción |
| Administrador | Todas las secciones |

Este bloque migra el acceso y los permisos. Las pantallas de operación clínica, inventario, ventas y producción todavía usan datos de prototipo; su integración con los endpoints actuales se hará en los siguientes bloques.

Validación:

```powershell
flutter analyze
flutter test
flutter build web
```

## Migración por bloques — bloque 2

- Búsqueda de ópticas por nombre, dirección y calificación; las respuestas antiguas no reemplazan una búsqueda más reciente.
- Reserva con ópticas activas y horarios futuros disponibles del backend, incluidos sábados y domingos. No se usan horarios ni confirmaciones de demostración.
- Mis citas carga el listado real, muestra errores con reintento y conserva el estado vacío cuando no existen reservas.
- Cancelación real con `PATCH /api/v1/appointments/{id}/status` y estado `CANCELLED`.
- Reprogramación con el flujo del backend: reservar un nuevo horario y luego cancelar la cita anterior. Si falla la cancelación, se informa que la nueva cita existe; reintentar solo cancela la anterior y no genera otra reserva.
- El estado `COMPLETED` se muestra como «Atendida». Las citas se ordenan por fecha y hora completas.

La duración proviene del horario elegido. La óptica asigna al profesional; la app no inventa nombres, distancias ni disponibilidad. Catálogo, órdenes, historia clínica y otras áreas todavía tienen datos de prototipo hasta sus siguientes bloques.
