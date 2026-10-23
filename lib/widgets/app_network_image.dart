import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary.withValues(alpha: 0.55),
        size: 36,
      ),
    );

    if (url.isEmpty) return fallback;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFE8EEE9),
        highlightColor: Colors.white,
        child: Container(width: width, height: height, color: Colors.white),
      ),
      errorWidget: (context, url, error) => fallback,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
