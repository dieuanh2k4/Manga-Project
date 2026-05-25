import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_cache_manager.dart';

class ProtectedNetworkImage extends StatelessWidget {
  const ProtectedNetworkImage({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingWidget,
  });

  final String imageUrl;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    final resolvedCacheKey = cacheKey ?? imageUrl;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: resolvedCacheKey,
      cacheManager: MangaImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: (context, imageProvider) {
        unawaited(MangaImageCacheManager.markCached(resolvedCacheKey));
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
      placeholder: (context, url) =>
          loadingWidget ??
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 18),
          ),
    );
  }
}
