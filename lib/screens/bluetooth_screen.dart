import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../services/bluetooth_service.dart';
import '../utils/constants.dart';

class BluetoothScreen extends StatefulWidget {
  final BluetoothService bluetoothService;
  final bool isDarkMode;

  const BluetoothScreen({
    super.key,
    required this.bluetoothService,
    required this.isDarkMode,
  });

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isScanning = false;
  String _statusMessage = 'Pronto';
  List<fbp.ScanResult> _devices = [];

  @override
  void initState() {
    super.initState();
    _listenToStatus();
    _listenToScanResults();
  }

  void _listenToStatus() {
    widget.bluetoothService.statusStream.listen((message) {
      if (mounted) {
        setState(() => _statusMessage = message);
      }
    });
  }

  void _listenToScanResults() {
    widget.bluetoothService.scanResults.listen((results) {
      if (mounted) {
        // Filtra solo ESP32
        setState(() {
          _devices = results.where((r) => 
            r.device.platformName.toLowerCase().contains('esp32')
          ).toList();
        });
      }
    });
  }

  Future<void> _autoConnect() async {
    setState(() {
      _isScanning = true;
      _statusMessage = '🔍 Ricerca ESP32...';
    });
    
    bool success = await widget.bluetoothService.autoConnect();
    
    if (mounted) {
      setState(() => _isScanning = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ESP32 connesso!'),
            backgroundColor: AppConstants.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ESP32 non trovato'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _manualScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scansione...';
    });
    
    await widget.bluetoothService.startScan();
    
    await Future.delayed(const Duration(seconds: 8));
    
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    bool success = await widget.bluetoothService.connectToDevice(device);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Connesso a ${device.platformName}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Connessione fallita')),
      );
    }
  }

  Future<void> _disconnect() async {
    await widget.bluetoothService.disconnectDevice();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnesso')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode 
        ? AppConstants.darkBackgroundColor 
        : AppConstants.backgroundColor;
    final cardColor = widget.isDarkMode 
        ? AppConstants.darkCardColor 
        : Colors.white;
    final textColor = widget.isDarkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Bluetooth ESP32'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: widget.bluetoothService.isConnected
                ? AppConstants.primaryGreen.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            child: Row(
              children: [
                Icon(
                  widget.bluetoothService.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: widget.bluetoothService.isConnected
                      ? AppConstants.primaryGreen
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pulsante grande "CONNETTI"
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (!widget.bluetoothService.isConnected) ...[
                  // Pulsante CONNETTI grande
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: _isScanning ? null : _autoConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isScanning ? Icons.search : Icons.bluetooth_searching,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isScanning ? 'RICERCA...' : 'CONNETTI ESP32',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tocca per connettere automaticamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else ...[
                  // Dispositivo connesso
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryGreen,
                        width: 3,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppConstants.primaryGreen,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CONNESSO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.bluetoothService.connectedDeviceName ?? 'ESP32',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _disconnect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'DISCONNETTI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Dispositivi trovati (opzionale)
          if (_devices.isNotEmpty && !widget.bluetoothService.isConnected)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Dispositivi trovati:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index].device;
                        return ListTile(
                          leading: const Icon(
                            Icons.bluetooth,
                            color: AppConstants.primaryGreen,
                          ),
                          title: Text(
                            device.platformName,
                            style: TextStyle(color: textColor),
                          ),
                          trailing: TextButton(
                            onPressed: () => _connectToDevice(device),
                            child: const Text('Connetti'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}