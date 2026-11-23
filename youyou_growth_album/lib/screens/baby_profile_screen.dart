import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'setup_screen.dart';

/// "我的"页：展示宝宝档案、精确年龄，以及后续版本功能说明
class BabyProfileScreen extends StatelessWidget {
  const BabyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final baby = provider.baby!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFFBEAF0),
                  child: const Icon(Icons.baby_ching, size: 44, color: Color(0xFFD4537E)),
                ),
                const SizedBox(height: 12),
                Text(baby.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(baby.ageText, style: const TextStyle(color: Color(0xFFD4537E), fontSize: 16)),
                const SizedBox(height: 4),
                Text('已陪伴 ${baby.daysOld} 天 · 第 ${baby.monthsOld + 1} 个月',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFD4537E)),
                title: const Text('修改宝宝档案'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SetupScreen(),
                )),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.face, color: Color(0xFFD4537E)),
                title: const Text('AI 识别样本管理'),
                subtitle: const Text('去"导入照片 → AI 自动筛选"里星标样本'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('后续版本会加入', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.show_chart, color: Colors.grey),
                title: Text('身高体重成长曲线'),
                trailing: Chip(label: Text('V2')),
              ),
              ListTile(
                leading: Icon(Icons.movie, color: Colors.grey),
                title: Text('一键生成成长视频'),
                trailing: Chip(label: Text('V2')),
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.grey),
                title: Text('家人共享'),
                trailing: Chip(label: Text('V2')),
              ),
              ListTile(
                leading: Icon(Icons.cloud, color: Colors.grey),
                title: Text('云备份防丢失'),
                trailing: Chip(label: Text('V2')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('所有数据仅保存在本机 · 保护隐私',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }
}
