# JWT for App auth, API key for internal services

- **App → Gallery**: JWT access tokens (15min) + refresh tokens (30 days), issued on email/password login. Tokens stored in Flutter secure storage (`flutter_secure_storage`).
- **Gallery → Splitter**: A single pre-shared API key, rotated via environment variable. No user identity needed — the Splitter only needs to know the caller is the Gallery.

## Why

- JWT is stateless, no server-side session store, fits a mobile-first architecture
- Refresh tokens allow long-lived sessions without re-login
- API key for internal service-to-service avoids JWT overhead where user identity is irrelevant
- Gallery is the sole caller of Splitter; no multi-tenancy needed on that boundary
