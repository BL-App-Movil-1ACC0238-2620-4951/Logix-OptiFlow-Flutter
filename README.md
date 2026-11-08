# Logix OptiFlow — Flutter

Cliente Flutter del mismo producto que la app Android [Logix-OptiFlow-Mobile](https://github.com/BL-App-Movil-1ACC0238-2620-4951/Logix-OptiFlow-Mobile).

Incluye las dos experiencias:

- **Paciente:** acceso, inicio, búsqueda de ópticas, reserva de citas, pedidos, catálogo, receta, historial, notificaciones y perfil.
- **Personal clínico:** jornada, agenda, fichas, inventario, producción, cotización, venta, alertas y reportes. El backend todavía no tiene login de staff, así que ese rol entra en modo demostración, igual que en Android.

## Backend

| Entorno | Base URL |
|--------|-----------|
| Producción (Render) | `https://logix-optiflow-back-end.onrender.com/` |
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
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/
```

En un celular físico usa la IP de tu PC en lugar de `10.0.2.2`. En escritorio o web usa `http://localhost:8080/`.

El catálogo de monturas, el inventario y la operación clínica usan los mismos datos de prototipo que la app Android cuando el API no los expone. Login, ópticas, horarios y reservas sí salen del backend.
