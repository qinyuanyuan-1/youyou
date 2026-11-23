import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// 人脸筛选服务（本地离线运行，照片不会上传到任何服务器）
///
/// 工作原理（大白话）：
/// 1. 你先圈 3~5 张"确定是优优"的照片当样本；
/// 2. App 用 Google ML Kit 在这几张照片里找到脸，把脸部区域缩成一张
///    很小的灰度"指纹"，存下来；
/// 3. 扫描相册时，同样提取每张照片里最大那张脸的指纹；
/// 4. 比较指纹的相似度，超过阈值就认为是优优的照片。
///
/// 重要说明（不夸大）：
/// 这是"几何 + 灰度指纹"的轻量方案，优点是免费、离线、快，
/// 缺点是不如专业人脸识别模型准：光线暗、侧脸、戴帽子、
/// 年龄跨度大时可能认错或漏认。所以它给的是"候选结果"，
/// 最终由你在界面上手动确认。阈值可以在设置里调高低。
/// 如果以后要更准，可把本文件替换为 TFLite 人脸向量模型。
/// ============================================================
class FaceRecognitionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  static const _sampleKey = 'face_samples_v1';
  static const _thresholdKey = 'face_threshold_v1';

  /// 默认相似度阈值（0~1）。越高越严格（更不容易误认，但可能漏认）。
  double _threshold = 0.72;
  double get threshold => _threshold;

  /// 样本指纹列表
  List<List<double>> _samples = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _threshold = prefs.getDouble(_thresholdKey) ?? 0.72;
    final raw = prefs.getStringList(_sampleKey) ?? <String>[];
    _samples = raw.map((s) {
      final list = jsonDecode(s) as List<dynamic>;
      return list.map((e) => (e as num).toDouble()).toList();
    }).toList();
  }

  Future<void> setThreshold(double value) async {
    _threshold = value.clamp(0.5, 0.95);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, _threshold);
  }

  bool get hasSamples => _samples.isNotEmpty;

  /// 删除全部样本（重新训练时用）
  Future<void> clearSamples() async {
    _samples = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sampleKey);
  }

  /// 把一张图片加入样本库。返回是否成功检测到脸。
  Future<bool> addSample(String imagePath) async {
    final fingerprint = await _fingerprintOf(imagePath);
    if (fingerprint == null) return false;
    _samples.add(fingerprint);
    await _persistSamples();
    return true;
  }

  /// 判断一张照片是否"像优优"。返回 0~1 的相似度，没有脸返回 null。
  Future<double?> similarity(String imagePath) async {
    if (_samples.isEmpty) return null;
    final fingerprint = await _fingerprintOf(imagePath);
    if (fingerprint == null) return null;
    double best = 0;
    for (final sample in _samples) {
      final s = _cosine(fingerprint, sample);
      if (s > best) best = s;
    }
    return best;
  }

  /// 判断相似度是否达到阈值
  bool isMatch(double similarity) => similarity >= _threshold;

  Future<void> _persistSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _samples.map((s) => jsonEncode(s)).toList();
    await prefs.setStringList(_sampleKey, raw);
  }

  /// 提取一张图里最大那张脸的"指纹"向量。
  /// 指纹 = 脸部灰度缩略图（16x16=256维） + 5个关键点的相对位置（10维）。
  Future<List<double>?> _fingerprintOf(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return null;

      // 取面积最大的那张脸（通常就是主角）
      faces.sort((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaB.compareTo(areaA);
      });
      final face = faces.first;

      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final box = face.boundingBox;
      // 稍微扩大一点裁剪范围，包含完整脸部
      final padX = (box.width * 0.1).round();
      final padY = (box.height * 0.1).round();
      final left = math.max(0, box.left - padX);
      final top = math.max(0, box.top - padY);
      final w = math.min(image.width - left, box.width + padX * 2);
      final h = math.min(image.height - top, box.height + padY * 2);
      if (w <= 0 || h <= 0) return null;

      final cropped = img.copyCrop(image, x: left, y: top, width: w, height: h);
      final small = img.copyResize(cropped, width: 16, height: 16);

      final vector = <double>[];
      // 灰度缩略图，归一化到 0~1
      for (var y = 0; y < 16; y++) {
        for (var x = 0; x < 16; x++) {
          final p = small.getPixel(x, y);
          final gray = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / 255.0;
          vector.add(gray);
        }
      }
      // 关键点相对位置（左眼、右眼、鼻子、左嘴、右嘴）
      final types = [
        FaceLandmarkType.leftEye,
        FaceLandmarkType.rightEye,
        FaceLandmarkType.noseBase,
        FaceLandmarkType.leftMouth,
        FaceLandmarkType.rightMouth,
      ];
      for (final t in types) {
        final lm = face.landmarks[t];
        if (lm != null) {
          vector.add(lm.position.x / image.width);
          vector.add(lm.position.y / image.height);
        } else {
          vector.add(0.5);
          vector.add(0.5);
        }
      }
      return vector;
    } catch (e) {
      debugPrint('人脸指纹提取失败: $e');
      return null;
    }
  }

  /// 余弦相似度
  double _cosine(List<double> a, List<double> b) {
    final len = a.length < b.length ? a.length : b.length;
    double dot = 0, na = 0, nb = 0;
    for (var i = 0; i < len; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  void dispose() {
    _detector.close();
  }
}
