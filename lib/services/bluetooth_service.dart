import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BluetoothService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;
  
  // UUID dell'ESP32 (devono corrispondere al codice Arduino)
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  
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

      // Ferma eventuali scan in corso
      await fbp.FlutterBluePlus.stopScan();
      
      // Avvia lo scan (durata 8 secondi per dare più tempo)
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      // Gestione errori
      print('Errore scan: $e');
    }
  }

  // Ferma lo scan
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  // Connetti a un dispositivo
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      print('Tentativo connessione a: ${device.platformName}');
      
      // Disconnetti il dispositivo precedente se esiste
      if (_connectedDevice != null) {
        await disconnectDevice();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Connetti con timeout più lungo
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      
      print('Connesso! Scoperta servizi...');
      _connectedDevice = device;

      // Aspetta un attimo prima di scoprire i servizi
      await Future.delayed(const Duration(milliseconds: 1000));

      // Scopri i servizi
      List<fbp.BluetoothService> services = await device.discoverServices();
      print('Trovati ${services.length} servizi');
      
      // Cerca il servizio specifico dell'ESP32
      for (fbp.BluetoothService service in services) {
        print('Servizio: ${service.uuid}');
        
        // Controlla se è il nostro servizio
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          print('✓ Servizio Pulse trovato!');
          
          // Cerca la caratteristica
          for (fbp.BluetoothCharacteristic char in service.characteristics) {
            print('  Caratteristica: ${char.uuid}');
            
            if (char.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              print('✓ Caratteristica trovata!');
              _characteristic = char;
              _connectionStateController.add(true);
              return true;
            }
          }
        }
      }
      
      // Se arriviamo qui, non abbiamo trovato il servizio
      print('❌ Servizio o caratteristica non trovati');
      await disconnectDevice();
      return false;
      
    } catch (e) {
      print('Errore connessione: $e');
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
        print('Disconnesso');
      }
    } catch (e) {
      print('Errore disconnessione: $e');
    } finally {
      _connectedDevice = null;
      _characteristic = null;
      _connectionStateController.add(false);
    }
  }

  // Invia comando all'ESP32
  Future<bool> sendCommand(String command) async {
    if (_characteristic == null || _connectedDevice == null) {
      print('Nessun dispositivo connesso');
      return false;
    }

    try {
      print('Invio comando: $command');
      await _characteristic!.write(
        command.codeUnits,
        withoutResponse: false,
      );
      print('Comando inviato con successo');
      return true;
    } catch (e) {
      print('Errore invio comando: $e');
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