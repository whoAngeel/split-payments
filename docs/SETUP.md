# Cómo correr el proyecto

## Requisitos

- Go 1.22+
- Flutter 3.44+
- PostgreSQL
- MinIO
- Docker (opcional, para despliegue)

---

## Desarrollo local

### 1. PostgreSQL

```bash
# En el puerto que use tu .env (5432 o 5433)
sudo -u postgres psql -c "CREATE USER openpayments WITH PASSWORD 'openpayments';"
sudo -u postgres psql -c "CREATE DATABASE openpayments OWNER openpayments;"
```

### 2. MinIO

```bash
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

### 3. Variables de entorno

Copiá y editá `backend/.env` desde `.env.example`.

### 4. Gallery API (puerto 4000)

```bash
cd backend
go run ./cmd/gallery
```

### 5. Splitter (puerto 4001)

```bash
cd backend
go run ./cmd/splitter
```

### 6. Seed (datos de prueba)

```bash
cd backend
go run ./cmd/seed
```

### 7. Tests

```bash
cd backend
go test ./internal/...
```

### 8. Flutter App

```bash
cd app
flutter pub get
flutter run
```

---

## Despliegue con Docker (homelab)

### 1. Configurar variables de entorno

Creá un archivo `.env` en la raíz del proyecto con las variables sensibles:

```bash
cp .env.example .env
# Editá WALLET_ADDRESS_URL, PRIVATE_KEY_PATH, KEY_ID, JWT_SECRET, INVITE_CODE
```

### 2. Subir los servicios

```bash
docker compose up -d
```

Esto levanta:
- PostgreSQL (puerto 5432)
- MinIO (puertos 9000, 9001)
- Gallery API (puerto 4000)
- Splitter (puerto 4001)
- Adminer (puerto 8070, opcional)

### 3. Crear un admin

```bash
curl -X POST http://<IP>:4000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "admin@test.com",
    "password": "password123",
    "name": "Admin",
    "role": "gallery_admin",
    "gallery_name": "Mi Galeria",
    "invite_code": "tu-codigo"
  }'
```

### 4. Seed (opcional)

```bash
docker compose exec gallery /gallery
# O ejecutar el seed localmente apuntando a la DB del contenedor
```

---

## Resumen de puertos

| Servicio | Puerto |
|---|---|
| Gallery API | 4000 |
| Splitter | 4001 |
| MinIO | 9000 |
| MinIO Console | 9001 |
| PostgreSQL | 5432 |
| Adminer | 8070 |
