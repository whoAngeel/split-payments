# Single key for Splitter authentication

The Splitter uses a single Ed25519 key pair to sign all Open Payments requests across all wallet providers (artisan, gallery, buyer). It does not store or manage per-party keys.

## Considered Options

- **Multiple keys per context** — a separate key for signing as gallery, as artisan, as platform. Rejected: the Splitter is a backend service, not a multi-tenant user agent. Compromise of one key implies compromise of the server anyway. No security gain for the operational complexity of key rotation, backup, and provider registration at N× scale.
- **Single key** — one key, registered as a client with each wallet provider. Chosen for simplicity and alignment with the official Open Payments split-payment guide, which uses a single client instance across all parties.
