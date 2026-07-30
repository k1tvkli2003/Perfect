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
      final visible = List<bool>.filled(image.width * image.height, false);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final alpha = rgba[((y * image.width) + x) * 4 + 3];
          if (alpha == 0) continue;
          if (alpha >= 128) visible[(y * image.width) + x] = true;
          minX = minX < x ? minX : x;
          minY = minY < y ? minY : y;
          maxX = maxX > x ? maxX : x;
          maxY = maxY > y ? maxY : y;
        }
      }

      var components = 0;
      final queue = <int>[];
      for (var index = 0; index < visible.length; index++) {
        if (!visible[index]) continue;
        components++;
        visible[index] = false;
        queue
          ..clear()
          ..add(index);
        for (var cursor = 0; cursor < queue.length; cursor++) {
          final current = queue[cursor];
          final x = current % image.width;
          final y = current ~/ image.width;
          for (var offsetY = -1; offsetY <= 1; offsetY++) {
            for (var offsetX = -1; offsetX <= 1; offsetX++) {
              if (offsetX == 0 && offsetY == 0) continue;
              final nextX = x + offsetX;
              final nextY = y + offsetY;
              if (nextX < 0 ||
                  nextX >= image.width ||
                  nextY < 0 ||
                  nextY >= image.height) {
                continue;
              }
              final next = (nextY * image.width) + nextX;
              if (!visible[next]) continue;
              visible[next] = false;
              queue.add(next);
            }
          }
        }
      }

      expect(<int>[
        rgba[3],
        rgba[((image.width - 1) * 4) + 3],
        rgba[(((image.height - 1) * image.width) * 4) + 3],
        rgba[((image.width * image.height) - 1) * 4 + 3],
      ], everyElement(0));
      expect(minX, lessThanOrEqualTo(45));
      expect(maxX, greaterThanOrEqualTo(467));
      expect(maxX - minX + 1, greaterThanOrEqualTo(420));
      expect(maxY - minY + 1, greaterThanOrEqualTo(495));
      expect((minY - (image.height - 1 - maxY)).abs(), lessThanOrEqualTo(2));
      expect(
        components,
        7,
        reason:
            'The selected Day Compass must preserve six distinct pastel '
            'modules plus its dark owner core.',
      );

      final centreOffset =
          (((image.height ~/ 2) * image.width) + (image.width ~/ 2)) * 4;
      expect(rgba[centreOffset + 3], greaterThan(240));
      expect(rgba[centreOffset], lessThan(90));
      expect(rgba[centreOffset + 1], lessThan(90));
      expect(rgba[centreOffset + 2], lessThan(90));
    },
  );
}
