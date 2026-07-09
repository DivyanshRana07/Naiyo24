import 'export_helper_stub.dart'
    if (dart.library.js_util) 'export_helper_web.dart'
    if (dart.library.html) 'export_helper_web.dart' as impl;

void downloadFile({
  required String filename,
  required String content,
  required String mimeType,
}) {
  impl.downloadFile(filename: filename, content: content, mimeType: mimeType);
}

void downloadBytes({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) {
  impl.downloadBytes(filename: filename, bytes: bytes, mimeType: mimeType);
}

void shareToWhatsApp({required String text}) {
  impl.shareToWhatsApp(text: text);
}

Future<String?> pickLogoImage() => impl.pickLogoImage();
