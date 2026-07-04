import 'package:flutter/material.dart';

/// Devuelve la URL de otra variante de una imagen subida por la app
/// (`..._thumb.jpg`, `..._small.jpg`, `..._medium.jpg`). Si la URL no sigue
/// ese patrón, la regresa intacta.
String imageVariant(String url, String suffix) {
  return url
      .replaceAll('_medium.jpg', '_$suffix.jpg')
      .replaceAll('_small.jpg', '_$suffix.jpg')
      .replaceAll('_thumb.jpg', '_$suffix.jpg');
}

/// Imagen de red con estados completos: placeholder tonal + progreso durante
/// la carga, fade-in al llegar, y fallback. Si [fallbackUrl] existe y la URL
/// principal falla (p.ej. variante `_small` de un upload viejo que no la
/// tiene), reintenta con el fallback antes de mostrar el ícono de error.
class AppImage extends StatefulWidget {
  final String url;
  final String? fallbackUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final double errorIconSize;

  const AppImage(
    this.url, {
    super.key,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.errorIconSize = 40,
  });

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  bool _usingFallback = false;

  @override
  void didUpdateWidget(AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _usingFallback = false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _usingFallback ? widget.fallbackUrl! : widget.url;

    return Image.network(
      url,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: widget.cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        if (!_usingFallback &&
            widget.fallbackUrl != null &&
            widget.fallbackUrl != widget.url) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _usingFallback = true);
          });
          return Container(color: cs.surfaceContainerHighest);
        }
        return Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: widget.errorIconSize,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        );
      },
    );
  }
}
