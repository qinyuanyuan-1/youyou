import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

/// 填写/修改宝宝名字和出生年月日
/// 首次启动（没有档案）时作为首页；从"我的"进入时为修改模式，保存后返回。
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController _nameController;
  late DateTime _birthDate;
  late final bool _isEdit;

  @override
  void initState() {
    super.initState();
    final baby = context.read<AppProvider>().baby;
    _isEdit = baby != null;
    _nameController = TextEditingController(text: baby?.name ?? '优优');
    _birthDate = baby?.birthDate ?? DateTime(2024, 1, 1);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写宝宝名字')));
      return;
    }
    await context.read<AppProvider>().saveBaby(name, _birthDate);
    // 修改模式下返回上一页；首次启动时 AppEntry 会自动切到主页
    if (_isEdit && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isEdit
          ? AppBar(title: const Text('修改宝宝档案'))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.baby_ching, size: 72, color: Color(0xFFD4537E)),
                  const SizedBox(height: 16),
                  Text(_isEdit ? '修改宝宝档案' : '欢迎来到成长相册',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('告诉我们宝宝的名字和出生日期', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '宝宝名字',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.grey.shade100,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFFD4537E)),
                    title: const Text('出生年月日'),
                    subtitle: Text('${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('保存', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
