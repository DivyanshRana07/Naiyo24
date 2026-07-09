import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadFile(
    {required String filename,
    required String content,
    required String mimeType}) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}

void downloadBytes(
    {required String filename,
    required List<int> bytes,
    required String mimeType}) {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob([uint8List.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}

void shareToWhatsApp({required String text}) {
  final encodedText = Uri.encodeComponent(text);
  final url = 'https://api.whatsapp.com/send?text=$encodedText';
  web.window.open(url, '_blank');
}

Future<String?> pickLogoImage() async {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'image/*';

  input.addEventListener('change', (web.Event event) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      return;
    }
    final file = files.item(0)!;
    final reader = web.FileReader();
    reader.readAsDataURL(file);
    
    reader.addEventListener('loadend', (web.Event ev) {
      final result = reader.result;
      if (result != null) {
        // In package:web, result could be JSString, convert to Dart String
        completer.complete(result.toString());
      } else {
        completer.complete(null);
      }
    }.toJS);
  }.toJS);

  input.click();
  return completer.future;
}
