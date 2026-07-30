import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected launcher source is transparent and fills its 512 box',
    () async {
      final data = await rootBundle.load('assets/brand/perfect-launcher.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      addTearDown(codec.dispose);
      final frame = await codec.getNextFrame();
      addTearDown(frame.image.dispose);
      final image = frame.image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      expect(image.width, 512);
      expect(image.height, 512);
      expect(pixels, isNotNull);

      final rgba = pixels!.buffer.asUint8List();
      var minX = image.width;
      var minY = image.height;
      var maxX = -1;
      var maxY = -1;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final alpha = rgba[((y * image.width) + x) * 4 + 3];
          if (alpha == 0) continue;
          minX = minX < x ? minX : x;
          minY = minY < y ? minY : y;
          maxX = maxX > x ? maxX : x;
          maxY = maxY > y ? maxY : y;
        }
      }

      expect(<int>[
        rgba[3],
        rgba[((image.width - 1) * 4) + 3],
        rgba[(((image.height - 1) * image.width) * 4) + 3],
        rgba[((image.width * image.height) - 1) * 4 + 3],
      ], everyElement(0));
      expect(minX, lessThanOrEqualTo(8));
      expect(maxX, greaterThanOrEqualTo(503));
      expect(maxX - minX + 1, greaterThanOrEqualTo(500));
      expect(maxY - minY + 1, greaterThanOrEqualTo(435));
      expect((minY - (image.height - 1 - maxY)).abs(), lessThanOrEqualTo(2));
    },
  );
}
