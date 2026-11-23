import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YouYouApp());
}

class YouYouApp extends StatelessWidget {
  const YouYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..load(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '优优成长相册',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4537E)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AppEntry(),
      ),
    );
  }
}

/// 启动入口：没建立宝宝档案就先去"设置宝宝"页，否则进主页。
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (provider.baby == null) return const SetupScreen();
    return const HomeScreen();
  }
}
