import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo_entry.dart';
import '../providers/app_provider.dart';
import '../services/date_service.dart';
import '../widgets/photo_viewer.dart';
import 'import_photos_screen.dart';

/// 时光相册：照片按"第几个月"分组展示，每组一个可展开的格子。
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final grouped = provider.photosGroupedByMonth();
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: provider.photos.isEmpty
          ? _EmptyState(onImport: () => _goImport(context))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: months.length,
              itemBuilder: (_, i) {
                final month = months[i];
                final list = grouped[month]!;
                return _MonthSection(month: month, photos: list);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4537E),
        onPressed: () => _goImport(context),
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: const Text('导入照片', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _goImport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportPhotosScreen()));
  }
}

/// 没有照片时的引导页
class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_album_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('还没有照片', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('从手机相册挑几张导进来吧', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
            onPressed: onImport,
            child: const Text('去导入照片'),
          ),
        ],
      ),
    );
  }
}

/// 某个月的照片分组
class _MonthSection extends StatelessWidget {
  final int month;
  final List<PhotoEntry> photos;
  const _MonthSection({required this.month, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(DateService.monthLabel(month),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('${photos.length}张', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
          ),
          itemCount: photos.length,
          itemBuilder: (_, i) {
            final photo = photos[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PhotoViewer(
                  paths: photos.map((p) => p.localPath).toList(),
                  initialIndex: i,
                ),
              )),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(photo.localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                  ),
                  if (photo.isSample)
                    const Positioned(
                      top: 4, right: 4,
                      child: Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 24),
      ],
    );
  }
}
