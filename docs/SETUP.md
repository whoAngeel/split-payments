# Cómo correr el proyecto

## Requisitos

- Go 1.22+
- Flutter 3.44+
- PostgreSQL (corriendo en puerto 5432 o 5433 según .env)
- MinIO (almacenamiento de imágenes)
- Docker (para MinIO, opcional)

---

## 1. PostgreSQL

Ya está corriendo en `localhost:5432`. La app espera `5433`. Cambiá el `.env`:

```bash
# backend/.env
DATABASE_URL=postgres://openpayments:openpayments@localhost:5432/openpayments?sslmode=disable
```

O si querés mantener el puerto 5433, creá la DB y el user:

```bash
sudo -u postgres psql -c "CREATE USER openpayments WITH PASSWORD 'openpayments';"
sudo -u postgres psql -c "CREATE DATABASE openpayments OWNER openpayments;"
```

---

## 2. MinIO

```bash
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

Verificar: `curl http://localhost:9000` debe responder.

---

## 3. Backend

### Variables de entorno

El archivo `backend/.env` ya está configurado. Ajustá `DATABASE_URL` al puerto correcto (5432 si usás el PostgreSQL del sistema).

### Gallery API (puerto 4000)

```bash
cd backend
go run ./cmd/gallery
```

### Splitter (puerto 4001)

En otra terminal:

```bash
cd backend
go run ./cmd/splitter
```

### Seed (datos de prueba)

```bash
cd backend
go run ./cmd/seed
```

### Tests

```bash
cd backend
go test ./internal/...
```

---

## 4. Flutter App

Ajustá la IP en `app/lib/config/app_config.dart` si tu máquina tiene otra IP:

```dart
const appConfig = AppConfig(baseUrl: 'http://192.168.1.13:4000');
```

Correr en dispositivo/emulador:

```bash
cd app
flutter pub get
flutter run
```

O compilar APK:

```bash
cd app
flutter build apk --debug
```

---

## 5. Crear un admin

```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "admin@test.com",
    "password": "password123",
    "name": "Admin",
    "role": "gallery_admin",
    "gallery_name": "Mi Galeria",
    "invite_code": "test123"
  }'
```

---

## Resumen de puertos

| Servicio | Puerto |
|---|---|
| Gallery API | 4000 |
| Splitter | 4001 |
| MinIO | 9000 |
| MinIO Console | 9001 |
| PostgreSQL | 5432 o 5433 |
