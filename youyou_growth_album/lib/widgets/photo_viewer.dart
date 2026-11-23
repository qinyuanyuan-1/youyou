import 'dart:io';

import 'package:flutter/material.dart';

/// 点击照片后的大图查看页（支持左右滑动、双指缩放）
class PhotoViewer extends StatelessWidget {
  final List<String> paths;
  final int initialIndex;

  const PhotoViewer({super.key, required this.paths, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${initialIndex + 1}/${paths.length}'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: paths.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.file(
              File(paths[i]),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
