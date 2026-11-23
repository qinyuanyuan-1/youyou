import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../models/photo_entry.dart';

/// 相册服务：读取系统相册里的照片，并把选中的照片复制一份到 App 私有目录。
/// 为什么要复制一份？因为系统相册里的原始文件路径可能变化，
/// 复制后 App 自己保管，数据更稳。
class GalleryService {
  final _uuid = const Uuid();

  /// 请求相册权限。返回 true 表示可以用。
  /// iOS 上还需要在 Info.plist 里写 NSPhotoLibraryUsageDescription，
  /// Android 需要在 AndroidManifest.xml 里写 READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE。
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result == PermissionState.limited;
  }

  /// 打开系统相册，返回所有图片资源（按时间从新到旧），供页面展示选择。
  Future<List<AssetEntity>> loadGalleryAssets({int page = 0, int size = 200}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return <AssetEntity>[];
    final assets = await albums.first.getAssetListRange(start: page * size, end: page * size + size);
    return assets;
  }

  /// 把选中的系统相册照片导入 App，生成一条 PhotoEntry。
  /// [babyMonth] 由页面根据"拍摄时间 + 宝宝生日"算好后传进来。
  Future<PhotoEntry> importAsset(AssetEntity asset, int babyMonth) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    // 复制原图到私有目录
    final file = await asset.file;
    if (file == null) {
      throw Exception('无法读取这张照片，可能原图已被删除');
    }
    final ext = _extensionOf(file.path);
    final newPath = '${photosDir.path}/${_uuid.v4()}$ext';
    await file.copy(newPath);

    return PhotoEntry(
      id: _uuid.v4(),
      localPath: newPath,
      takenAt: asset.createTime,
      babyMonth: babyMonth,
    );
  }

  /// 复制一张本地图片（成长记录里的配图）到 App 私有目录，返回新路径。
  Future<String> copyLocalImage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final ext = _extensionOf(sourcePath);
    final newPath = '${photosDir.path}/${_uuid.v4()}$ext';
    await File(sourcePath).copy(newPath);
    return newPath;
  }

  String _extensionOf(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }
}
