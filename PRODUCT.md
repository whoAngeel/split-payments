# Product

## Register

product

## Users

Dos personas principales, en orden de prioridad de implementación:

1. **Comprador** — Una persona común comprando productos artesanales a través de una galería. No necesita saber que el pago se divide; solo quiere ver productos, pagar de forma segura, y recibir confirmación. Puede estar en zonas con conectividad limitada, usar datos móviles, o ser un adulto mayor con poca experiencia en apps financieras.

2. **Operador de galería** — El dueño o administrador de una galería que registra artesanos, configura comisiones, gestiona productos, y monitorea pagos. Necesita claridad sobre el estado de los pagos split y las liquidaciones pendientes.

## Product Purpose

Una plataforma móvil que permite a galerías de arte y artesanía vender productos con pagos divididos automáticos: el comprador paga una sola vez, y el dinero se distribuye instantáneamente entre los artesanos (con la comisión de la galería), usando el protocolo Open Payments de Interledger.

El éxito es que el comprador nunca sepa que el pago se dividió — la complejidad financiera desaparece detrás de una experiencia de compra simple y confiable.

## Brand Personality

- **Artesanal** — La app honra el oficio y la pieza única. No es una tienda masiva; cada producto tiene una historia, un rostro, un taller. La UI debe sentirse cuidada, no producida en serie.
- **Cálido** — Colores tierra, texturas sutiles, fotografía grande de producto. La calidez viene del contenido (las piezas, los artesanos), no de la decoración de la interfaz.
- **Confiable** — El usuario está moviendo dinero real. Cada pantalla del flujo de pago debe transmitir seguridad sin sentirse bancaria o fría.

Referencia visual: [Crumbly Artisan Bakery](https://dribbble.com/shots/27191694-Crumbly-Artisan-Bakery-Landing-Page) en Dribbble — artesanal, texturizado, cálido, pero contemporáneo y limpio.

## Anti-references

- **NO rústico-folclórico.** Nada de fuentes script mexicanas, patrones de talavera, iconografía prehispánica decorativa, ni paletas saturadas tipo Mercado de Artesanías. Lo auténtico no es sinónimo de folclórico.
- **NO fintech corporativo.** Nada de azul navy + blanco estéril, gráficas de velas, tipografía geométrica fría, o lenguaje de "soluciones financieras integradas". Esto no es Stripe ni PayPal.
- **NO startup SaaS genérico.** Nada de purple-to-blue gradients, glassmorphism decorativo, ilustraciones vectoriales corporate-Memphis, o pantallas de onboarding con 3 slides genéricas.

## Design Principles

1. **El producto es el protagonista.** La interfaz se retira; la fotografía del producto, el nombre del artesano, y el precio ocupan el primer plano. La UI es marco, no cuadro.
2. **Confianza invisible.** La complejidad del split payment, GNAP consent, y liquidaciones existe pero el comprador nunca la ve. Cada paso del checkout se siente como cualquier otra compra en una app.
3. **Una sola mano.** Cada pantalla, botón, y transición usa el mismo lenguaje visual. Si dos pantallas tienen un botón "Confirmar", se ven idénticos. La consistencia construye confianza.
4. **Diseñado para Oaxaca, no para San Francisco.** La app funciona con mala conectividad (offline-friendly donde sea posible), targets táctiles generosos para manos que trabajan, tipografía legible para adultos mayores, y bajo consumo de datos.
5. **Calidez sin decoración.** El calor no viene de ornamentos, sombras, o gradients — viene del contenido real (las piezas artesanales, las fotos, los nombres de los artesanos) presentado con espacio, tipografía cuidada, y una paleta tierra contenida.

## Accessibility & Inclusion

- **WCAG AA** como base mínima — contraste ≥4.5:1 en cuerpo de texto, ≥3:1 en texto grande.
- **Targets táctiles ≥48px** — considerando usuarios con manos grandes o poca precisión motriz fina.
- **Tipografía legible** — tamaños generosos, sin condensadas ni decorativas en UI. Soporte para escala de fuente del sistema.
- **Bajo consumo de datos** — imágenes optimizadas, sin autoplay de video, carga progresiva.
- **Offline-friendly** — colas de operaciones pendientes, estados claros cuando no hay conexión, sin pantallas en blanco ni spinners eternos.
- **Lenguaje claro** — español sencillo, sin jerga financiera. Los términos del dominio (consentimiento GNAP, split payment) nunca se muestran al comprador.
