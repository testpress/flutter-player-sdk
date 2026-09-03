import 'generated/native_player_api.g.dart' as pigeon;

export 'generated/native_player_api.g.dart'
    show WatermarkAnimation, WatermarkAnimationType;

abstract class BaseWatermarkConfig {
  final int x;
  final int y;
  final double opacity;

  BaseWatermarkConfig({
    this.x = 0,
    this.y = 0,
    this.opacity = 1.0,
  });

  pigeon.BaseWatermarkConfig toPigeon();
}

class TextWatermarkConfig extends BaseWatermarkConfig {
  final String text;
  final int color;
  final double textSize;
  final pigeon.WatermarkAnimation? animation;

  TextWatermarkConfig({
    required this.text,
    super.x = 0,
    super.y = 0,
    this.color = 0xFFFFFFFF,
    this.textSize = 14.0,
    super.opacity = 0.3,
    this.animation,
  });

  @override
  pigeon.BaseWatermarkConfig toPigeon() => pigeon.BaseWatermarkConfig(
        text: pigeon.TextWatermarkConfig(
          text: text,
          x: x,
          y: y,
          color: color,
          textSize: textSize,
          opacity: opacity,
          animation: animation,
        ),
      );
}

typedef WatermarkConfig = TextWatermarkConfig;

class ImageWatermarkConfig extends BaseWatermarkConfig {
  final String imageUrl;
  final int width;
  final int height;

  ImageWatermarkConfig({
    required this.imageUrl,
    this.width = 48,
    this.height = 48,
    super.x = 92,
    super.y = 88,
    super.opacity = 1.0,
  });

  @override
  pigeon.BaseWatermarkConfig toPigeon() => pigeon.BaseWatermarkConfig(
        image: pigeon.ImageWatermarkConfig(
          imageUrl: imageUrl,
          width: width,
          height: height,
          x: x,
          y: y,
          opacity: opacity,
        ),
      );
}
