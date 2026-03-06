import 'dart:io';
import 'package:exif/exif.dart';

Future<int?> extractYearFromImage(String imagePath) async {
  try {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);

    if (data.isEmpty) return null;

    final dateOriginal = data['EXIF DateTimeOriginal'];
    final dateTime = data['EXIF DateTime'];
    final dateDigitized = data['EXIF DateTimeDigitized'];

    String? dateString;
    if (dateOriginal != null) {
      dateString = dateOriginal.toString();
    } else if (dateDigitized != null) {
      dateString = dateDigitized.toString();
    } else if (dateTime != null) {
      dateString = dateTime.toString();
    }

    if (dateString == null) return null;

    final parts = dateString.split(' ');
    if (parts.isEmpty) return null;

    final datePart = parts[0];
    final yearPart = datePart.split(':');
    if (yearPart.isEmpty) return null;

    return int.tryParse(yearPart[0]);
  } catch (e) {
    return null;
  }
}
