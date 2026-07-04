<!-- SEED: re-run /impeccable document once there's code to capture the actual tokens and components. -->

---
name: OpenPayments
description: Plataforma móvil de pagos divididos para galerías de arte y artesanía
colors:
  primary: "#C2573A"
  tierra-clara: "#FAF6F3"
  barro: "#F0EBE7"
  madera: "#3A302B"
  arena: "#736761"
  piedra: "#CBC5C1"
  primary_container: "#FCE4DD"
  on_primary_container: "#6B1D0A"
typography:
  heading:
    fontFamily: "System sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.25
  title:
    fontFamily: "System sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1.3
  body:
    fontFamily: "System sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "System sans-serif"
    fontSize: "14px"
    fontWeight: 500
    letterSpacing: "0.02em"
  caption:
    fontFamily: "System sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
rounded:
  sm: "8px"
  md: "12px"
  lg: "20px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
---

# Design System: OpenPayments

## 1. Overview

**Creative North Star: "El Taller"**

The visual system of a working artisan's workshop translated into a digital product. Warm but not nostalgic. Handcrafted but not rustic. The interface is the quiet backdrop — clay walls, wooden workbench, morning light — against which the art (the products, the artisans' stories, the craft itself) takes center stage. The UI never competes with the content; it frames it.

This is a product surface, not a brand destination. The design serves the task: browse, pay, confirm. Every visual choice either helps that task or gets out of the way. The warmth comes from the content — terracotta mugs, woven textiles, carved wood — not from decorative flourishes in the UI. The trust comes from consistency and restraint: same button, same gesture, same feedback, every screen.

The system explicitly rejects three aesthetics: the rustic-folclórico cliché (no script fonts, no talavera patterns, no saturated mercado palettes), the fintech corporate coldness (no navy-and-white sterility, no candlestick charts, no "financial solutions" language), and the SaaS startup generic (no purple-to-blue gradients, no glassmorphism, no corporate-Memphis illustrations).

**Key Characteristics:**
- Restrained accent — one terracotta touch per screen, never more
- Single warm sans family carries the entire UI — headings, buttons, labels, body
- Flat by default — surfaces are tonal, not shadowed; depth comes from content hierarchy
- Photography-first — product images are the largest element on any browse screen
- Responsive motion only — state transitions, feedback, no page-load choreography

## 2. Colors

**The Restrained Rule.** One accent color on ≤10% of any given screen. Its rarity is the point. The palette is neutral with a warm tint toward the brand hue; the accent appears only on primary actions, current selection, and critical state indicators.

### Primary
- **Terracota Cocido** (#C2573A): The sole accent. Used exclusively for primary buttons, active tab indicators, selected states, and the single most important action on any screen. Its warmth anchors the brand without overwhelming it. Never used as decoration, never as a background, never on inactive elements. On primary: #FFFFFF (4.5:1 contrast). Container: #FCE4DD, on container: #6B1D0A.

### Neutral
- **Tierra Clara** (#FAF6F3): Content surface background. A warm-tinted near-white. Replaces stark white on every screen; the subtle warmth is the difference between a gallery and a spreadsheet.

- **Barro** (#F0EBE7): Elevated surface (cards, sheets, dialogs). Slightly darker than Tierra Clara, same hue family. The tonal shift creates separation without shadows.

- **Madera** (#3A302B): Body text. A warm dark brown. Never pure #000; the warm undertone keeps long reading comfortable and on-brand. 11.9:1 contrast against Tierra Clara.

- **Arena** (#736761): Muted text, captions, secondary labels. 5.1:1 contrast against Tierra Clara, 4.6:1 against Barro. Warmer and lighter than Madera.

- **Piedra** (#CBC5C1): Borders, dividers, disabled states. The lightest visible stroke; present but barely.

## 3. Typography

**Single warm sans family carries the entire UI.** One well-tuned humanist sans for headings, buttons, labels, body, and data — chosen for legibility and warmth, not geometry or decoration. No display font, no serif pairing, no decorative scripts.

**Character:** Warm without being soft. The font has a human touch (open apertures, slightly organic curves) but stays disciplined — this is product UI, not editorial design. Legibility at small sizes is the binding constraint; personality is a bonus, not the goal.

### Hierarchy
- **Heading** (Semibold, 24px, 1.25 line-height): Page titles, section headers. Used sparingly — one per screen. `[font pairing to be chosen at implementation]`
- **Title** (Medium, 18px, 1.3 line-height): Card titles, product names, artisan names. The workhorse headline.
- **Body** (Regular, 16px, 1.5 line-height, max 65ch): Product descriptions, payment details, confirmation messages. Generous size for readability by older users.
- **Label** (Medium, 14px, 0.02em letter-spacing): Button text, form labels, tab labels, chip text. Uppercase only when the platform convention demands it (Material 3 top app bar titles); otherwise sentence case.
- **Caption** (Regular, 13px, 1.4 line-height): Prices, metadata, timestamps, secondary info.

## 4. Elevation

**The Flat-By-Default Rule.** Surfaces are flat at rest. Depth is conveyed through tonal layering (Tierra Clara → Barro), not shadows. The tonal shift is enough; the content hierarchy does the rest.

Shadows appear only as a response to interactive state:
- **Floating action button** (the single primary action): a soft ambient shadow on hover/press, gone at rest
- **Bottom sheet / modal**: a single diffuse backdrop scrim, no surface shadow
- **Cards**: no shadow. Tonal background shift + optional hairline border (Piedra) for separation

If a surface looks like it needs a shadow, add spacing or tonal contrast first. Shadows are the last resort.

## 5. Components

*[Components will be documented once the Flutter widget library is implemented. Re-run `/impeccable document` to capture them.]*

## 6. Do's and Don'ts

### Do:
- **Do** use a single terracotta accent on ≤10% of any screen. Primary button, active tab, one indicator.
- **Do** let product photography be the largest element on browse and product screens.
- **Do** use tonal background shifts (Tierra Clara → Barro) for surface separation instead of shadows.
- **Do** keep body text at ≥16px with ≥4.5:1 contrast against its background.
- **Do** make every tappable target ≥48px. Buttons, list items, chips, icons.
- **Do** show clear offline states — no blank screens, no infinite spinners.
- **Do** use the same button shape, input style, and icon vocabulary across every screen.

### Don't:
- **Don't** use script fonts, talavera patterns, pre-Hispanic iconography, or saturated mercado palettes. No rustic-folclórico.
- **Don't** use navy-and-white, candlestick charts, or "financial solutions" language. No fintech corporate.
- **Don't** use purple-to-blue gradients, glassmorphism, or corporate-Memphis illustrations. No SaaS startup generic.
- **Don't** use the terracotta accent as a background fill, a decorative element, or on inactive states. It's an accent, not a theme.
- **Don't** add shadows to cards or surfaces at rest. Flat is the default.
- **Don't** use `Colors.deepPurple` or any Material 3 default seed color. The palette is terracotta-earth.
- **Don't** invent custom scrollbars, non-standard form controls, or decorative modals. Earned familiarity wins.
- **Don't** show the user terms like "GNAP consent", "split payment", or "outgoing payment grant". The buyer sees "Confirmar pago".
