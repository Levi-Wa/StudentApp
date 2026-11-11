import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionsService {
  static Future<bool> requestSystemPermissions() async {
    try {
      final status = await ph.Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasAllPermissions() async {
    try {
      final status = await ph.Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
