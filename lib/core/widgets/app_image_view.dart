import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable image widget that transparently renders:
/// - Base64 data strings (e.g., from ImagePicker)
/// - Network URLs (http/https)
/// - Local file paths
/// - Flutter asset paths
class AppImageView extends StatelessWidget {
  final String? imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImageView({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

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
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
      );
    } else {
      // Attempt base64 decoding
      try {
        String cleanBase64 = src;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 = cleanBase64.replaceAll('\n', '').replaceAll('\r', '').trim();
        final bytes = base64Decode(cleanBase64);
        imgWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
        );
      } catch (_) {
        // Fallback to local file path
        try {
          final file = File(src);
          if (file.existsSync()) {
            imgWidget = Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) =>
                  errorWidget ?? _defaultErrorWidget(),
            );
          } else {
            imgWidget = errorWidget ?? _defaultErrorWidget();
          }
        } catch (_) {
          imgWidget = errorWidget ?? _defaultErrorWidget();
        }
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imgWidget,
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
