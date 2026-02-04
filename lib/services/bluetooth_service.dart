import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BluetoothService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;
  
  // Stream per i dispositivi trovati
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;
  
  // Stream per lo stato della connessione
  final StreamController<bool> _connectionStateController = 
      StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;
  
  bool get isConnected => _connectedDevice != null;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  // Inizia lo scan dei dispositivi Bluetooth
  Future<void> startScan() async {
    try {
      // Controlla se il Bluetooth è supportato
      if (await fbp.FlutterBluePlus.isSupported == false) {
        return;
      }

      // Avvia lo scan (durata 4 secondi)
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      // Gestione errori silenziosa
    }
  }

  // Ferma lo scan
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  // Connetti a un dispositivo
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      // Disconnetti il dispositivo precedente se esiste
      if (_connectedDevice != null) {
        await disconnectDevice();
      }

      // Connetti
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Scopri i servizi
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Trova la caratteristica per scrivere (cerca servizio custom ESP32)
      for (fbp.BluetoothService service in services) {
        for (fbp.BluetoothCharacteristic char in service.characteristics) {
          if (char.properties.write) {
            _characteristic = char;
            break;
          }
        }
        if (_characteristic != null) break;
      }

      _connectionStateController.add(true);
      return true;
    } catch (e) {
      _connectedDevice = null;
      _characteristic = null;
      _connectionStateController.add(false);
      return false;
    }
  }

  // Disconnetti dispositivo
  Future<void> disconnectDevice() async {
    try {
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

  // Invia comando all'ESP32
  Future<bool> sendCommand(String command) async {
    if (_characteristic == null || _connectedDevice == null) {
      return false;
    }

    try {
      await _characteristic!.write(command.codeUnits, withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Invia notifica di soglia superata
  Future<bool> sendThresholdAlert(double currentDb) async {
    // Comando: "ALERT:XX" dove XX è il valore dei dB
    String command = 'ALERT:${currentDb.toStringAsFixed(0)}';
    return await sendCommand(command);
  }

  // Pulisci risorse
  void dispose() {
    disconnectDevice();
    _connectionStateController.close();
  }
}