import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FrameImage extends StatelessWidget {
  const FrameImage({super.key, this.path = '', this.height = 150});
  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height, width: double.infinity,
      decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(14)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.remove_red_eye_outlined, size: 48, color: AppColors.navyBlue),
        SizedBox(height: 8), Text('Sin fotografía'),
      ]),
    );
    if (path.isEmpty) return placeholder;
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: path.startsWith('https://')
      ? Image.network(path, height: height, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => placeholder)
      : Image.asset(path, height: height, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => placeholder));
  }
}
