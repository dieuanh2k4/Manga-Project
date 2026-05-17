import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    // lần đầu ảnh load từ url, package cached_network_image sẽ lưu ảnh vào cache
    // lần sau nếu gọi đúng url hoặc cacheKey thì sẽ lấy từ cache thay vì url
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey:
          cacheKey ??
          imageUrl, // đảm bảo mỗi ảnh có 1 key, ảnh page thì ảnh là url
      width: width,
      height: height,
      fit: fit,
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
