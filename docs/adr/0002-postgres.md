# PostgreSQL for persistence

Both Gallery and Splitter use PostgreSQL as their database. A single database cluster with separate logical databases or schemas per service.

## Why

- Data is naturally relational (users, products, expenses, settlements, sessions)
- Foreign keys enforce referential integrity across settlement lifecycles
- sqlc provides type-safe Go queries without an ORM
- Migrations via golang-migrate give reproducible schema evolution

## Considered Options

- **Firestore (used in hackathon)** — rejected. NoSQL made cross-entity consistency harder; the hackathon's state machine already mapped cleanly to relational rows.
- **SQLite** — rejected. Insufficient for concurrent write workloads and two-service access.
