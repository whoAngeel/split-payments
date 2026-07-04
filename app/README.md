# Split Payments App

Flutter app for the Open Payments / Interledger artisan gallery.

---

## Emuladores

```bash
# Listar emuladores disponibles
flutter emulators

# Lanzar emulador (escoge uno)
flutter emulators --launch Pixel_8a
flutter emulators --launch pixel

# Ver dispositivos conectados
flutter devices
```

## Correr la app

```bash
# En el emulador activo
flutter run

# En dispositivo específico (ID del `flutter devices`)
flutter run -d <device-id>

# En Linux desktop
flutter run -d linux

# Con hot reload activo (ya incluido en `flutter run`)
# r → hot reload
# R → hot restart
# q → salir
```

## Build

```bash
# APK debug
flutter build apk --debug

# APK release
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle
```

## Dependencias

```bash
flutter pub get
flutter pub upgrade
```

## Análisis y tests

```bash
flutter analyze
flutter test
```
