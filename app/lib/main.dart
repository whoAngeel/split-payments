import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Error boundary de render: si un widget truena en build/layout, se
  // muestra un aviso compacto en su lugar en vez de una pantalla en blanco.
  // El detalle completo sigue saliendo en los logs (FlutterError.onError).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 18, color: Color(0xFF410002)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Algo salió mal al mostrar esta sección',
                    style: TextStyle(
                      color: Color(0xFF410002),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF410002), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: OpenPaymentsApp()));
}
