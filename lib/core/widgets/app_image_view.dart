import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable image widget that transparently renders:
/// - Base64 data strings (e.g., from ImagePicker)
/// - Network URLs (http/https)
/// - Local file paths
/// - Flutter asset paths
///
/// Also provides full-screen pinch-to-zoom viewing support and cached memory
/// playback with gapless rendering to prevent image flickering during rebuilds.
class AppImageView extends StatelessWidget {
  static final Map<String, Uint8List> _base64Cache = {};
  final String? imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableFullScreenOnTap;
  final String? fullScreenTitle;

  const AppImageView({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.enableFullScreenOnTap = false,
    this.fullScreenTitle,
  });

  /// Opens an interactive full-screen viewer with pinch-to-zoom & pan.
  static void showFullScreenViewer(
    BuildContext context,
    String imageSource, {
    String? title,
  }) {
    if (imageSource.trim().isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.92),
        pageBuilder: (context, _, __) {
          final TransformationController transformController =
              TransformationController();

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  // Interactive Zoomable Image
                  Center(
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (transformController.value != Matrix4.identity()) {
                          transformController.value = Matrix4.identity();
                        } else {
                          transformController.value = Matrix4.identity()
                            ..scale(2.5);
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: transformController,
                        minScale: 0.5,
                        maxScale: 6.0,
                        clipBehavior: Clip.none,
                        child: AppImageView(
                          imageSource: imageSource,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Top Header with Title and Close Button
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title ?? 'Image Preview',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Pinch to zoom • Double tap to reset',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            splashRadius: 20,
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Reset Zoom Button at Bottom
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Material(
                      color: Colors.black.withOpacity(0.65),
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white24),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.fit_screen_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Reset Zoom',
                        onPressed: () {
                          transformController.value = Matrix4.identity();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageSource == null || imageSource!.trim().isEmpty) {
      return placeholder ?? _defaultErrorWidget();
    }

    final src = imageSource!.trim();
    Widget imgWidget;

    if (src.startsWith('http://') || src.startsWith('https://')) {
      imgWidget = Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        },
      );
    } else if (src.startsWith('assets/')) {
      imgWidget = Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
      );
    } else {
      // Attempt base64 decoding with static memory cache & gapless playback
      try {
        String cleanBase64 = src;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 =
            cleanBase64.replaceAll('\n', '').replaceAll('\r', '').trim();

        Uint8List? bytes = _base64Cache[cleanBase64];
        if (bytes == null) {
          bytes = base64Decode(cleanBase64);
          // Bound cache size to prevent memory leaks if many images are loaded
          if (_base64Cache.length > 100) {
            _base64Cache.remove(_base64Cache.keys.first);
          }
          _base64Cache[cleanBase64] = bytes;
        }

        imgWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
        );
      } catch (_) {
        // Fallback to local file path
        if (!kIsWeb) {
          try {
            final file = File(src);
            if (file.existsSync()) {
              imgWidget = Image.file(
                file,
                width: width,
                height: height,
                fit: fit,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    errorWidget ?? _defaultErrorWidget(),
              );
            } else {
              imgWidget = errorWidget ?? _defaultErrorWidget();
            }
          } catch (_) {
            imgWidget = errorWidget ?? _defaultErrorWidget();
          }
        } else {
          imgWidget = errorWidget ?? _defaultErrorWidget();
        }
      }
    }

    if (borderRadius != null) {
      imgWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imgWidget,
      );
    }

    if (enableFullScreenOnTap) {
      return GestureDetector(
        onTap: () => showFullScreenViewer(
          context,
          src,
          title: fullScreenTitle,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            imgWidget,
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.zoom_in_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return imgWidget;
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
      ),
    );
  }
}
