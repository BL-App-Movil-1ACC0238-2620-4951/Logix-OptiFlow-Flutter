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

Login, ópticas, horarios, reservas, catálogo, inventario y atención clínica consumen el backend. Las áreas comerciales, de producción y administración todavía tienen funciones de prototipo pendientes de migración.

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

El bloque 1 migró el acceso y los permisos. La integración del catálogo y el inventario se describe en el bloque 3; clínica, ventas y producción se completarán en los siguientes bloques.

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

La duración proviene del horario elegido. La óptica asigna al profesional; la app no inventa nombres, distancias ni disponibilidad. Las áreas de prototipo que siguen pendientes se detallan al final.

## Migración por bloques — bloque 3

- Catálogo y destacados desde `GET /api/v1/inventory/frames`. Los enlaces y búsquedas usan el SKU real, con precios en PEN y decimales conservados.
- Detalle por SKU; el personal consulta el stock de la óptica asignada a su sesión. El catálogo de pacientes no afirma disponibilidad cuando el API no la informa.
- Inventario por óptica, cantidades y mínimos reales. Asesores y administradores pueden consultarlo y actualizar precios.
- Los administradores registran ingresos de proveedores con cantidad de 1 a 1000 y mínimo opcional. Las salidas se generan mediante ventas; se retiraron los ajustes manuales que solo modificaban la pantalla.
- Movimientos de entrada y salida por SKU, con filtro de fechas. Un ingreso confirmado no se reporta como fallido si una consulta posterior de stock falla, para evitar registros duplicados al reintentar.
- La búsqueda por SKU permite consultar una etiqueta escrita. La captura con cámara y el visor AR no forman parte de este bloque; se retiraron las simulaciones de detección de rostro y stock ficticio.
- Cuando no existe fotografía en el API, se muestra un marcador sin atribuirle la imagen de otra montura.

También se pueden ejecutar las comprobaciones de contratos HTTP sin iniciar Flutter Test:

```powershell
dart --packages=.dart_tool/package_config.json test/support/inventory_api_checks.dart
```

Órdenes, historia clínica, ventas, agenda del personal y administración todavía tienen áreas de prototipo para los siguientes bloques.

## Migración por bloques — bloque 4: personal, según Movile

La referencia funcional y visual es `Logix-OptiFlow-Movile`, especialmente `StaffViewModel.kt`, `NewAppointmentViewModel.kt`, `StaffPatientRecordViewModel.kt`, `StaffTabScreens.kt` y `StaffClinicalScreens.kt`. Se mantienen la jerarquía de pantallas, tarjetas, colores, filtros y navegación del módulo al adaptarlos a widgets Flutter.

- Directorio real de pacientes, búsqueda local por nombre/correo/teléfono, total y nuevos del mes. El contador de fichas usa `GET /clinical-records/summary`.
- Registro con nombre, correo, teléfono, DNI de 8 dígitos como contraseña temporal y nacimiento opcional `dd/mm/aaaa`. El registro conserva la sesión del personal; no inicia sesión como el paciente creado.
- Agenda de la óptica asignada y fecha elegida, semana de lunes a sábado como en Movile. Excluye citas canceladas; la sala de espera se calcula desde 15 minutos antes del inicio hasta el fin. Las horas y fechas de operación usan America/Lima (UTC-5).
- Nueva cita de paso único: paciente registrado, fecha y horario libre real de la óptica. La ficha preselecciona al paciente. Si falla la reserva, se vuelve a leer disponibilidad, como en Movile.
- Ficha de consulta con perfil, última prescripción, próxima cita y orden de lentes real; los errores de cada sección no se muestran como datos de demostración. Un identificador inexistente nunca abre la ficha de otra persona.
- Los formularios y la ficha ocultan la barra inferior como en Android. Los accesos y las consultas respetan el rol.

La captura de la atención clínica se incorpora en el bloque 5. Las transiciones de producción, ventas, administración y los demás módulos se migrarán después. Los botones «Llamar» y «Mensaje» conservan el comportamiento sin acción que tienen en la pantalla de referencia de Movile.

Comprobaciones de contratos y reglas de paridad que no requieren Flutter Test:

```powershell
dart --packages=.dart_tool/package_config.json test/support/staff_api_checks.dart
```

## Migración por bloques — bloque 5: atención clínica

Referencia: `ClinicalCareViewModel.kt` y `screens/ClinicalCareScreen.kt` de Movile. La atención se abre desde la sala de espera o la ficha del paciente con sus identificadores reales; el acceso general permite elegir una cita pendiente de hoy.

1. **Examen:** `POST /clinical-records`, observaciones de hasta 500 caracteres.
2. **Antecedentes:** `PUT /clinical-records/{id}/medical-history`. Alergias y enfermedades separadas por comas, punto y coma o líneas, sin duplicados; hasta 20 elementos de 100 caracteres por campo y antecedentes familiares de hasta 1000.
3. **Receta:** `POST /clinical-records/{id}/prescription`, seguida de `PATCH /appointments/{id}/status` con `COMPLETED`.

Se conservan los rangos del formulario de Movile y del backend: esfera ±30, cilindro ±10, eje entero 0–180, adición opcional 0–4, tratamiento y montura opcionales de hasta 255 caracteres.

Una ficha ya abierta se retoma en su paso pendiente. Un 409 permite recuperar lo guardado desde otro intento o dispositivo. Si la receta se confirma y falla cerrar la cita, el formulario indica ese estado y reintenta únicamente el cierre. No vuelve a crear la receta ni muestra «Atención finalizada» antes de confirmar `COMPLETED`. Las citas canceladas, asociaciones de paciente/cita incorrectas y sesiones cerradas bloquean los envíos.

El flujo se implementó separado de Flutter para ejecutar sus secuencias completas y errores con el cliente HTTP y repositorio reales, usando respuestas de servidor simuladas:

```powershell
dart --packages=.dart_tool/package_config.json test/support/clinical_flow_checks.dart
```

La compilación web y estas comprobaciones no sustituyen una prueba de usuario con una cuenta de personal y el backend desplegado. Ventas, transiciones de producción, administración y otras funciones de Movile siguen en los próximos bloques.
