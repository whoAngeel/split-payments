# Deploy — Homelab

## Mapeo de servicios existentes

| Puerto | Ocupado por | ¿Conflicto? |
|---|---|---|
| 4000 | rago-app-1 | ❌ Lo usa otro proyecto |
| 4001 | interledger-backend | ❌ Lo usa otro proyecto |
| 5433 | rago-postgres-1 (postgres:17) | ✅ Podemos reusar |
| 9000-9001 | minio (quay.io/minio) | ✅ Podemos reusar |
| 80/443 | nginx-proxy-manager | ✅ Reverse proxy disponible |

## Puertos propuestos

| Servicio | Puerto |
|---|---|
| Gallery API | 4003 |
| Splitter | 4004 |

## Servicios a reusar

| Servicio | Contenedor | Qué necesitamos |
|---|---|---|
| PostgreSQL | `rago-postgres-1` (puerto 5433) | Credenciales para crear DB `openpayments` |
| MinIO | `minio` (puerto 9000) | `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
| Nginx Proxy Manager | `nginx-proxy-manager` | Opcional: dominio + SSL |

## Pasos

1. **Crear DB** en `rago-postgres-1`:
```bash
docker exec -it rago-postgres-1 psql -U rago -c "CREATE DATABASE openpayments;"
docker exec -it rago-postgres-1 psql -U rago -c "CREATE USER openpayments WITH PASSWORD '728pOI3IFoHouYxf';"
docker exec -it rago-postgres-1 psql -U rago -c "GRANT ALL ON DATABASE openpayments TO openpayments;"
```

2. **Crear bucket en MinIO** (si no existe):
```bash
# Usar la consola web: http://<IP>:9001
# O por CLI
```

3. **Configurar .env** con los datos del homelab:
```env
JWT_SECRET=finish-senor-speech-feels-queen
INVITE_CODE=Uz9zbpta19gPXn27c2MR
SPLITTER_API_KEY=alexa-cory-findings-palm-meryl
SPLITTER_PUBLIC_URL=http://192.168.1.21:4004
DATABASE_URL=postgres://openpayments:728pOI3IFoHouY@rago-postgres-1:5432/openpayments?sslmode=disable
MINIO_ENDPOINT=192.168.1.21:9000
MINIO_ACCESS_KEY=<de minio>
MINIO_SECRET_KEY=<de minio>
MINIO_BUCKET=gallery-artisan
WALLET_ADDRESS_URL=ttps://ilp.interledger-test.dev/angeel
KEY_ID=374bb267-30da-44a3-989e-16ef6bff458a
PRIVATE_KEY_PATH=./private.key
```

4. **Desplegar**:
```bash
docker compose up -d --build
```
