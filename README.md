# Logix OptiFlow — Flutter

Versión Flutter de la app Android [Logix-OptiFlow-Mobile](https://github.com/BL-App-Movil-1ACC0238-2620-4951/Logix-OptiFlow-Mobile), para pacientes y personal de la óptica.

Backend: `https://logix-optiflow-back-end.onrender.com/api/v1/` (la primera petición puede tardar un minuto si Render está dormido).

Cuenta de demostración: `demo.paciente@optiflow.pe` / `Optiflow123`

## Ejecutar

```powershell
flutter pub get
flutter run
```

Con el backend en tu PC:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1/
```

## APK de producción

Crea `android/key.properties` (no se sube a git) con la ruta al archivo de firma:

```properties
release.signing.properties=C:/ruta/a/keystore.properties
```

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://logix-optiflow-back-end.onrender.com/api/v1/
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## iOS (solo en Mac)

Abre `ios/Runner.xcworkspace` en Xcode, elige tu equipo en **Signing & Capabilities** y agrega `-ObjC` y `-all_load` en **Other Linker Flags** (para el probador virtual).

El simulador de iOS no tiene cámara: el probador avisa que no está disponible y en el escáner se escribe el SKU. Las notificaciones push solo funcionan en Android.
