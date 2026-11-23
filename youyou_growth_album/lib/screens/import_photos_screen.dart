import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/gallery_service.dart';

/// 导入照片页：
/// - Tab1 手动挑选：从相册多选，导入后按拍摄时间自动归到对应月龄
/// - Tab2 AI 自动筛选：先圈样本，再扫描相册把"像宝宝"的照片列为候选批量导入
class ImportPhotosScreen extends StatefulWidget {
  const ImportPhotosScreen({super.key});

  @override
  State<ImportPhotosScreen> createState() => _ImportPhotosScreenState()
      with SingleTickerProviderStateMixin;
}

class _ImportPhotosScreenState extends State<ImportPhotosScreen> {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _gallery = GalleryService();
  List<AssetEntity> _assets = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _hasPermission = false;
  bool _scanning = false;
  final Map<String, double> _candidates = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _gallery.requestPermission();
    if (!ok && mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相册权限才能读取照片，请在系统设置里开启')),
      );
      return;
    }
    final assets = await _gallery.loadGalleryAssets();
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _assets = assets;
        _loading = false;
      });
    }
  }

  /// 手动导入选中的照片
  Future<void> _importSelected() async {
    final provider = context.read<AppProvider>();
    final baby = provider.baby!;
    int done = 0;
    try {
      for (final id in _selected) {
        final entity = _assets.firstWhere((a) => a.id == id);
        final month = baby.monthAt(entity.createTime);
        final photo = await _gallery.importAsset(entity, month);
        await provider.addPhoto(photo);
        done++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入 $done 张照片')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  /// AI 扫描：对每张相册照片算相似度，列出超过阈值的候选
  Future<void> _scanWithAI() async {
    final face = context.read<AppProvider>().faceService;
    if (!face.hasSamples) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在"手动挑选"里，把确定是宝宝正脸的照片标为样本（星标）')),
      );
      return;
    }
    setState(() => _scanning = true);
    _candidates.clear();
    for (final asset in _assets) {
      final file = await asset.file;
      if (file == null) continue;
      final sim = await face.similarity(file.path);
      if (sim != null && face.isMatch(sim)) _candidates[asset.id] = sim;
    }
    if (mounted) setState(() => _scanning = false);
  }

  /// 一键把候选照片全部导入
  Future<void> _importCandidates() async {
    final provider = context.read<AppProvider>();
    final baby = provider.baby!;
    int done = 0;
    for (final id in _candidates.keys) {
      final entity = _assets.firstWhere((a) => a.id == id);
      final month = baby.monthAt(entity.createTime);
      final photo = await _gallery.importAsset(entity, month);
      await provider.addPhoto(photo);
      done++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 已导入 $done 张候选照片，请再人工核对一下')),
      );
      Navigator.of(context).pop();
    }
  }

  /// 把一张相册照片加入样本库
  Future<void> _addSample(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;
    final ok = await context.read<AppProvider>().faceService.addSample(file.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '已加入样本库' : '这张照片没检测到清晰正脸，换一张试试'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入照片'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '手动挑选'), Tab(text: 'AI 自动筛选')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? const Center(child: Text('没有相册权限'))
              : TabBarView(
                  controller: _tab,
                  children: [_buildManualGrid(), _buildAiPanel()],
                ),
    );
  }

  Widget _buildManualGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4,
            ),
            itemCount: _assets.length,
            itemBuilder: (_, i) {
              final asset = _assets[i];
              final picked = _selected.contains(asset.id);
              return GestureDetector(
                onTap: () => setState(() => picked ? _selected.remove(asset.id) : _selected.add(asset.id)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetEntityImage(asset, isOriginal: false, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
                    if (picked)
                      Container(
                        color: const Color(0x55000000),
                        child: const Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.check_circle, color: Color(0xFFD4537E), size: 22),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
              onPressed: _selected.isEmpty ? null : _importSelected,
              child: Text('导入选中（${_selected.length}）'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiPanel() {
    final face = context.watch<AppProvider>().faceService;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('第一步：圈样本', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('在下方挑一张宝宝正脸，点"加为样本"，建议收集 3~5 张。',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('相似度阈值：${face.threshold.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await face.clearSamples();
                      setState(() => _candidates.clear());
                    },
                    child: const Text('清空样本'),
                  ),
                ],
              ),
              Slider(
                value: face.threshold,
                min: 0.5, max: 0.95, divisions: 9,
                onChanged: (v) async {
                  await face.setThreshold(v);
                  setState(() {});
                },
              ),
              OutlinedButton.icon(
                onPressed: _scanning ? null : _scanWithAI,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_scanning ? '扫描中…' : '第二步：扫描相册'),
              ),
              if (_candidates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('找到 ${_candidates.length} 张候选，确认后导入：',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _candidates.isEmpty
              ? GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (_, i) {
                    final asset = _assets[i];
                    return GestureDetector(
                      onTap: () => _addSample(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AssetEntityImage(asset, isOriginal: false, fit: BoxFit.cover),
                          const Positioned(
                            top: 2, right: 2,
                            child: Icon(Icons.star_border, color: Colors.amber, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4,
                  ),
                  itemCount: _candidates.keys.length,
                  itemBuilder: (_, i) {
                    final id = _candidates.keys.elementAt(i);
                    final asset = _assets.firstWhere((a) => a.id == id);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetEntityImage(asset, isOriginal: false, fit: BoxFit.cover),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(2),
                            child: Text('${(_candidates[id]! * 100).round()}%',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4537E)),
              onPressed: _candidates.isEmpty ? null : _importCandidates,
              child: Text('导入候选（${_candidates.length}）'),
            ),
          ),
        ),
      ],
    );
  }
}
