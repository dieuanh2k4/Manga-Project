import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProtectedNetworkImage extends StatefulWidget {
  const ProtectedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  @override
  State<ProtectedNetworkImage> createState() => _ProtectedNetworkImageState();
}

class _ProtectedNetworkImageState extends State<ProtectedNetworkImage> {
  late Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageBytes(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant ProtectedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _loadImageBytes(widget.imageUrl);
    }
  }

  Future<Uint8List?> _loadImageBytes(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return null;
    }

    final response = await http.get(
      uri,
      headers: const {
        'Cache-Control': 'no-store, no-cache, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }

    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child:
                widget.loadingWidget ??
                const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child:
                widget.errorWidget ??
                const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 18),
                ),
          );
        }

        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
