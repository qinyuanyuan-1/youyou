import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/gallery_service.dart';

/// 成长记录页：写日记，发布后自动带"日期+星期+宝宝第几天"
class GrowthRecordScreen extends StatefulWidget {
  const GrowthRecordScreen({super.key});

  @override
  State<GrowthRecordScreen> createState() => _GrowthRecordScreenState();
}

class _GrowthRecordScreenState extends State<GrowthRecordScreen> {
  final _controller = TextEditingController();
  String? _photoPath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    // 复制一份到 App 私有目录，避免临时路径失效
    final saved = await GalleryService().copyLocalImage(x.path);
    setState(() => _photoPath = saved);
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('写点什么再发布吧')));
      return;
    }
    await context.read<AppProvider>().addRecord(text, photoPath: _photoPath);
    _controller.clear();
    setState(() => _photoPath = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发布')));
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AppProvider>().records;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '记录优优今天的成长瞬间…',
                        border: InputBorder.none,
                      ),
                    ),
                    if (_photoPath != null) ...[
                      Stack(
                        children: [
                          Image.file(File(_photoPath!), height: 120, fit: BoxFit.cover),
                          Positioned(
                            right: 4, top: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54, radius: 14,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () => setState(() => _photoPath = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image, color: Color(0xFFD4537E)),
                          onPressed: _pickImage,
                          tooltip: '加照片',
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
                          onPressed: _publish,
                          child: const Text('发布'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('还没有成长记录', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r = records[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r.dateLabel, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                    onPressed: () => context.read<AppProvider>().removeRecord(r.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('宝宝第 ${r.dayLabel} 天',
                                  style: const TextStyle(color: Color(0xFFD4537E), fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(r.content),
                              if (r.photoPath != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(r.photoPath!), maxHeight: 180, fit: BoxFit.cover),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
