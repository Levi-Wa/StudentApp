import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_text.dart';

class PermissionsService {
  static Future<bool> requestSystemPermissions() async {
    final permissions = [
      ph.Permission.notification,
      ph.Permission.storage,
      ph.Permission.locationWhenInUse,
    ];

    // Запрашиваем все разрешения через системные диалоги
    final statuses = await permissions.request();

    // Проверяем, все ли разрешения получены
    bool allGranted = true;
    for (final status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        print('Разрешение не получено: $status');
      }
    }

    print('Все разрешения получены: $allGranted');
    return allGranted;
  }


  static Future<bool> hasAllPermissions() async {
    final permissions = [ph.Permission.notification, ph.Permission.storage, ph.Permission.locationWhenInUse];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }

    return true;
  }
}

