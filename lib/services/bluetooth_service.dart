import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BluetoothService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectTimer;
  
  // UUID dell'ESP32 - HARDCODED, l'utente non li vedrà mai
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String deviceName = "ESP32_Pulse"; // Nome fisso da cercare
  
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;
  
  final StreamController<bool> _connectionStateController = 
      StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;
  
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;
  
  bool get isConnected => _connectedDevice != null && _characteristic != null;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  // AUTO-SCAN e AUTO-CONNESSIONE
  Future<bool> autoConnect() async {
    try {
      _statusController.add('🔍 Ricerca ESP32...');
      
      if (await fbp.FlutterBluePlus.isSupported == false) {
        _statusController.add('❌ Bluetooth non supportato');
        return false;
      }

      // Avvia scan
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      
      // Aspetta che trovi ESP32_Pulse
      await for (List<fbp.ScanResult> results in fbp.FlutterBluePlus.scanResults) {
        for (fbp.ScanResult result in results) {
          if (result.device.platformName.toLowerCase().contains('esp32')) {
            // TROVATO! Connetti automaticamente
            await fbp.FlutterBluePlus.stopScan();
            _statusController.add('✓ ESP32 trovato!');
            return await connectToDevice(result.device);
          }
        }
      }
      
      await fbp.FlutterBluePlus.stopScan();
      _statusController.add('❌ ESP32 non trovato');
      return false;
      
    } catch (e) {
      _statusController.add('Errore: $e');
      return false;
    }
  }

  // Scan manuale (per la schermata Bluetooth)
  Future<void> startScan() async {
    try {
      if (await fbp.FlutterBluePlus.isSupported == false) {
        return;
      }
      await fbp.FlutterBluePlus.stopScan();
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      // Ignora errori
    }
  }

  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  // Connetti a un dispositivo
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      _statusController.add('🔗 Connessione...');
      
      if (_connectedDevice != null) {
        await disconnectDevice();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Listener per la connessione
      _connectionSubscription = device.connectionState.listen((state) async {
        if (state == fbp.BluetoothConnectionState.connected) {
          _statusController.add('✓ Connesso');
          _connectionStateController.add(true);
        } else if (state == fbp.BluetoothConnectionState.disconnected) {
          _statusController.add('⚠️ Disconnesso');
          _connectionStateController.add(false);
          _characteristic = null;
          
          // AUTO-RICONNESSIONE dopo 3 secondi
          _scheduleReconnect(device);
        }
      });

      // Connetti
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Scopri servizi
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Cerca servizio e caratteristica
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (fbp.BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              _characteristic = char;
              _connectionStateController.add(true);
              _statusController.add('✅ ESP32 pronto!');
              
              // Test connessione
              await sendCommand('TEST');
              return true;
            }
          }
        }
      }
      
      _statusController.add('❌ Servizio non trovato');
      await disconnectDevice();
      return false;
      
    } catch (e) {
      _statusController.add('Errore connessione: $e');
      _connectedDevice = null;
      _characteristic = null;
      _connectionStateController.add(false);
      return false;
    }
  }

  // Pianifica riconnessione automatica
  void _scheduleReconnect(fbp.BluetoothDevice device) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      _statusController.add('🔄 Riconnessione...');
      await connectToDevice(device);
    });
  }

  Future<void> disconnectDevice() async {
    try {
      _reconnectTimer?.cancel();
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      // Ignora errori
    } finally {
      _connectedDevice = null;
      _characteristic = null;
      _connectionStateController.add(false);
    }
  }

  Future<bool> sendCommand(String command) async {
    if (_characteristic == null) {
      return false;
    }

    try {
      if (_connectedDevice == null) {
        return false;
      }

      var connectionState = await _connectedDevice!.connectionState.first;
      if (connectionState != fbp.BluetoothConnectionState.connected) {
        return false;
      }

      await _characteristic!.write(
        command.codeUnits,
        withoutResponse: false,
      );
      
      if (command.startsWith('ALERT')) {
        _statusController.add('⚠️ Alert inviato');
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendThresholdAlert(double currentDb) async {
    String command = 'ALERT:${currentDb.toStringAsFixed(0)}';
    bool success = await sendCommand(command);
    
    // Se fallisce, tenta di riconnettersi
    if (!success && _connectedDevice != null) {
      await connectToDevice(_connectedDevice!);
      return await sendCommand(command);
    }
    
    return success;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionSubscription?.cancel();
    disconnectDevice();
    _connectionStateController.close();
    _statusController.close();
  }
}