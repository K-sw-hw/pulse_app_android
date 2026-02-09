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
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  // Verifica se il permesso è già stato dato
  static Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }
  
  // Richiede permessi Bluetooth
  static Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      // Verifica se qualche permesso è permanentemente negato
      bool anyPermanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied
      );
      if (anyPermanentlyDenied) {
        await openAppSettings();
      }
    }
    
    return allGranted;
  }
}