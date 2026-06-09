# Gallery

The business-logic layer for the art gallery use case. Manages artisans, products, commission rules, and buyer interactions. This is the initial consumer of the Splitter, but the Splitter itself is domain-agnostic.

## Language

### Actors

**Artisan**:
A creator who supplies products sold through a gallery. Receives their share of a split payment directly.
_Avoid_: Creator, maker, seller

**Gallery**:
A venue or platform that sells products on behalf of artisans. Receives a commission from each split payment.
_Avoid_: Shop, store, venue

**Buyer**:
A person who purchases a product and makes a single payment that is split between the gallery and the artisan.
_Avoid_: Customer, client, purchaser

### Pricing

**Base Price**:
The amount an artisan sets for their product. This is what the artisan receives per sale.
_Avoid_: Artisan price, net price

**Commission Rate**:
A percentage the gallery applies to the base price. The gallery's share equals `base_price × commission_rate`.
_Avoid_: Fee, markup, gallery cut

**Split Rule**:
The computed division of a payment into shares, derived from a Base Price and a Commission Rate. Not stored statically — calculated at payment time.
_Avoid_: Split config, division rule
