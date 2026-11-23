import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'growth_record_screen.dart';
import 'skill_screen.dart';
import 'timeline_screen.dart';
import 'baby_profile_screen.dart';

/// 主页：底部 4 个 Tab（时光相册 / 成长记录 / 技能 / 我的）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _pages = const [
    TimelineScreen(),
    GrowthRecordScreen(),
    SkillScreen(),
    BabyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final baby = context.watch<AppProvider>().baby!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${baby.name}的成长相册'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('第${baby.daysOld}天', style: const TextStyle(fontSize: 15))),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: '相册'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: '成长记录'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: '技能'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
