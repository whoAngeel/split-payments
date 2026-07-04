import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<File> fixExifOrientation(File file) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return file;

  final oriented = img.bakeOrientation(decoded);
  final fixed = img.encodeJpg(oriented, quality: 85);
  final tmpFile = File('${file.parent.path}/fixed_${file.uri.pathSegments.last}');
  await tmpFile.writeAsBytes(Uint8List.fromList(fixed));

  return tmpFile;
}
