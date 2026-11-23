import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

/// 技能页：记录新学会的技能，时间线倒序展示
class SkillScreen extends StatefulWidget {
  const SkillScreen({super.key});

  @override
  State<SkillScreen> createState() => _SkillScreenState();
}

class _SkillScreenState extends State<SkillScreen> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showAddSheet() {
    _nameController.clear();
    _noteController.clear();
    _date = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('新学会的技能', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '技能名称', hintText: '例如：自己穿鞋', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Color(0xFFD4537E)),
              title: Text('${_date.year}年${_date.month}月${_date.day}日'),
              trailing: const Text('修改'),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                await context.read<AppProvider>().addSkill(
                      name,
                      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                      learnedAt: _date,
                    );
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<AppProvider>().skills;
    return Scaffold(
      body: skills.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('还没有记录技能', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: skills.length,
              itemBuilder: (_, i) {
                final s = skills[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFBEAF0),
                      child: const Icon(Icons.star, color: Color(0xFFD4537E), size: 18),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.dateLabel} · 第${s.dayLabel}天${s.note != null ? '\n${s.note}' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => context.read<AppProvider>().removeSkill(s.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4537E),
        onPressed: _showAddSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
