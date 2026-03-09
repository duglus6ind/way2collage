import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getMarkerIconFromData(
  IconData iconData,
  Color color, {
  double size = 120,
}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  final double radius = size / 2.0;

  // Shadow
  final Paint shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawCircle(Offset(radius, radius + 4), radius, shadowPaint);

  // Background circle
  final Paint backgroundPaint = Paint()..color = Colors.white;
  canvas.drawCircle(Offset(radius, radius), radius, backgroundPaint);

  // Icon
  final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: TextStyle(
      fontSize: size * 0.65,
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      color: color,
    ),
  );
  textPainter.layout();

  textPainter.paint(
    canvas,
    Offset(radius - (textPainter.width / 2), radius - (textPainter.height / 2)),
  );

  final ui.Picture picture = pictureRecorder.endRecording();
  final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}
