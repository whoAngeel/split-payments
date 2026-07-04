# Sesión 2026-07-03 — Optimización de build Docker + Recuperación de contraseñas

Resumen de los cambios hechos en esta sesión y los pasos pendientes para dejar todo funcionando en el homelab.

---

## 1. Optimización del build Docker (backend)

### Problema

Cada `docker compose up -d --build` tardaba **+1000 segundos**.

### Causas encontradas

1. **Sin cache de compilación de Go**: cada build recompilaba las ~200 dependencias de `go.sum` desde cero, en las dos imágenes (gallery y splitter).
2. **Sin `.dockerignore`**: el contexto de build subía 73 MB de `backend/tmp/` (artefactos de `air`). Además, como `COPY . .` incluía `tmp/`, cualquier rebuild de air invalidaba la capa de build de Docker.
3. `private.key` entraba al contexto de build (riesgo innecesario).

### Cambios aplicados

| Archivo | Cambio |
|---|---|
| `backend/.dockerignore` | **Nuevo.** Excluye `tmp/`, binarios `gallery`/`splitter`, `private.key`, `.env*`, Dockerfiles. |
| `backend/Dockerfile.gallery` | Cache mounts de BuildKit: `/go/pkg/mod` (módulos) y `/root/.cache/go-build` (objetos compilados). |
| `backend/Dockerfile.splitter` | Ídem. El cache se comparte entre ambas imágenes. |

### Resultado verificado

- Rebuild incremental con cambio de código real: **~3.3 segundos** (medido localmente).
- El **primer build en el homelab seguirá siendo lento** (cache frío, compila todo una vez). Del segundo en adelante: segundos.
- Builds en paralelo de ambas imágenes (opcional): `COMPOSE_BAKE=true docker compose up -d --build` (requiere compose v2.22+).

---

## 2. Montaje de `private.key` como volumen

### Problema

`PRIVATE_KEY_PATH=./private.key` apuntaba a un archivo que **nunca existió dentro del contenedor**: el stage final del Dockerfile solo copia el binario, y compose no montaba nada.

### Cambios aplicados

En `docker-compose.yml`, para **gallery** y **splitter**:

```yaml
environment:
  PRIVATE_KEY_PATH: /private.key   # fijo, ya no viene del .env
volumes:
  - ./backend/private.key:/private.key:ro
```

En `.env.production` local se comentó la línea `PRIVATE_KEY_PATH` (compose la ignora ahora).

**Requisito**: la key debe existir en `./backend/private.key` relativo al repo en el homelab (confirmado que ahí está).

---

## 3. Recuperación de contraseñas (backend + app Flutter)

### Diseño

Flujo con **código de 6 dígitos** enviado por email (sin deep links, apto para app móvil):

1. `POST /api/auth/forgot-password` `{email}` → genera código de 6 dígitos (crypto/rand), guarda su hash SHA-256 en la tabla nueva `password_resets`, expira en **15 minutos**. Responde 200 siempre — no revela si la cuenta existe.
2. `POST /api/auth/reset-password` `{email, code, new_password}` → valida y cambia la contraseña (mínimo 8 caracteres).

Propiedades de seguridad:
- Código de **un solo uso**.
- Máximo **5 intentos** fallidos por código.
- Pedir un código nuevo invalida los anteriores.
- Comparación en tiempo constante; respuestas de error genéricas.

### Entrega del código: SMTP con fallback a logs

Paquete nuevo `backend/internal/gallery/mailer`:

- **`SMTPMailer`** — se activa si `SMTP_HOST` está definido. Usa `net/smtp` con auth PLAIN + STARTTLS (puerto 587, compatible con Gmail app password).
- **`LogMailer`** — fallback cuando no hay SMTP: el código sale en los logs del gallery con nivel WARN.

El arranque del gallery loggea cuál quedó activo:
- `smtp mailer configured` — enviando emails reales.
- `smtp not configured, password reset codes will be written to the log` — modo logs.

### Archivos backend

| Archivo | Cambio |
|---|---|
| `internal/gallery/model/password_reset.go` | **Nuevo.** Modelo `PasswordReset` (user_id, code_hash, expires_at, attempts, used_at). |
| `internal/gallery/mailer/mailer.go` | **Nuevo.** Interfaz `Mailer` + `SMTPMailer` + `LogMailer`. |
| `internal/gallery/service/auth.go` | `RequestPasswordReset`, `ResetPassword`, `SetMailer`. |
| `internal/gallery/handler/auth.go` | Handlers `ForgotPassword`, `ResetPassword`. |
| `internal/gallery/config/config.go` | Campos `SMTP_*`. |
| `cmd/gallery/main.go` | Rutas nuevas, AutoMigrate de `PasswordReset`, selección de mailer. |
| `internal/gallery/service/password_reset_test.go` | **Nuevo.** 6 tests del flujo. |

### Archivos app Flutter

| Archivo | Cambio |
|---|---|
| `lib/screen/auth/forgot_password_screen.dart` | **Nuevo.** Pantalla en dos pasos: email → enviar código; luego código + contraseña nueva, con botón "Resend code". |
| `lib/service/auth_service.dart` | Métodos `forgotPassword`, `resetPassword`. |
| `lib/router/app_router.dart` | Ruta `/forgot-password`, accesible sin sesión. |
| `lib/screen/auth/login_screen.dart` | Link "Forgot password?". |

### Verificación

- `go test ./...` — todo pasa (incluye 6 tests nuevos: flujo feliz, código incorrecto, reuso, máximo de intentos, rotación de códigos, email desconocido).
- E2E manual con curl contra el servidor corriendo: registro → forgot → código extraído del log → reset → login con contraseña nueva OK, contraseña vieja rechazada, código reusado rechazado.
- `flutter analyze` limpio en los archivos tocados.

### Nota de seguridad

Un código de 6 dígitos hasheado con SHA-256 es fuerza-brutable **offline** si se filtra la base de datos. Con el cap de 5 intentos online + TTL de 15 minutos el riesgo práctico es bajo para esta app. Si algún día quieres endurecerlo: bcrypt sobre el código o tokens largos con deep link.

---

## 4. Qué tienes que hacer tú

### Hoy — desplegar en el homelab

```bash
# 1. En esta máquina: commit + push (aún sin commitear)
# 2. En el homelab:
cd ~/split-payments        # o donde tengas el repo
git pull

# 3. Verifica que la key está donde compose la espera:
ls -l ./backend/private.key

# 4. Rebuild (este primero será lento — cache frío; los siguientes, segundos):
docker compose --env-file .env.production up -d --build
```

En el `.env.production` del homelab:
- Agrega el bloque `SMTP_*` vacío (o copia el de este repo).
- Opcional: borra/comenta `PRIVATE_KEY_PATH` (compose la ignora).

### Mientras no haya SMTP

Los códigos de recuperación salen en los logs del gallery:

```bash
docker logs openpayments-gallery 2>&1 | grep "restablecer"
```

### Mañana — configurar el correo

1. Consigue credenciales SMTP. Con Gmail: activa verificación en 2 pasos y crea una **app password** en https://myaccount.google.com/apppasswords
2. Rellena en `.env.production` del homelab:

   ```bash
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=tu-correo@gmail.com
   SMTP_PASSWORD=la-app-password
   SMTP_FROM=tu-correo@gmail.com   # opcional, default = SMTP_USER
   ```

3. Recrea el contenedor (sin `--build`, solo toma el env nuevo):

   ```bash
   docker compose --env-file .env.production up -d
   ```

4. Verifica en logs que diga `smtp mailer configured` y prueba el flujo desde la app ("Forgot password?" en el login).

### Pendiente en esta máquina (dev)

- Tenías un `go run ./cmd/gallery` corriendo desde hacía ~9h con código viejo; lo maté durante las pruebas y dejé corriendo el binario nuevo en `:4000`. Para volver a tu flujo normal: mata ese proceso y relanza `go run ./cmd/gallery`.
- Los cambios de esta sesión están **sin commitear** (backend, app, compose, .env.example, este doc).
