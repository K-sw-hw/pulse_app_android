import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Richiede permesso microfono
  static Future<bool> requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      status = await Permission.microphone.request();
      return status.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Apri settings per dare permesso manualmente
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  // Verifica se il permesso è già stato dato
  static Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }
}