# Single Gallery per User

Each User can own at most one Gallery. A `gallery_admin` role implies exactly one Gallery; a `buyer` implies none.

## Why

- Simplifies JWT: the token carries a single `gallery_id`, eliminating the need to select a gallery context on every request.
- Simplifies the Flutter app: no gallery-picker UI, no switching between galleries.
- Aligns with the initial use case: a gallery operator runs one gallery. Multi-gallery support adds complexity without current demand.
- If multi-gallery is needed later, the constraint can be lifted with a migration — the data model (1:N User↔Gallery) already supports it.

## Considered Alternative

**Multiple galleries per user.** Rejected because it adds routing complexity (gallery selection, scoping every admin operation) and JWT ambiguity for no current benefit. The 1:N relationship in the schema is preserved as future-proofing, only the application layer enforces the constraint.
