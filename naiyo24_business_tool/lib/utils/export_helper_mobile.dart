import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void downloadFile(
    {required String filename,
    required String content,
    required String mimeType}) {
  // Not supported on mobile — no-op
}

void downloadBytes(
    {required String filename,
    required List<int> bytes,
    required String mimeType}) {
  // Not supported on mobile — no-op
}

void shareToWhatsApp({required String text}) {
  // Not supported on mobile via this helper — no-op
}

/// Pick an image from the gallery and return it as a base64 data URL,
/// matching the format returned by the web implementation.
Future<String?> pickLogoImage() async {
  final picker = ImagePicker();
  final XFile? picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1200,
    maxHeight: 1200,
  );

  if (picked == null) return null;

  final bytes = await File(picked.path).readAsBytes();
  final base64Str = base64Encode(bytes);
  // Return as a data URL (same format as the web FileReader.readAsDataURL)
  final ext = picked.path.split('.').last.toLowerCase();
  final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
  return 'data:$mime;base64,$base64Str';
}
