import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../services/bluetooth_service.dart';
import '../services/settings_service.dart';
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

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    await widget.bluetoothService.startScan();
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    final success = await widget.bluetoothService.connectToDevice(device);
    
    if (!mounted) return;
    
    if (success) {
      await SettingsService.setConnectedDeviceId(device.remoteId.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connesso a ${device.platformName}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connessione fallita')),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    await widget.bluetoothService.disconnectDevice();
    await SettingsService.setConnectedDeviceId(null);
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
        title: const Text('Bluetooth'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.black,
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          // Dispositivo connesso
          if (widget.bluetoothService.isConnected)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.primaryGreen, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, 
                      color: AppConstants.primaryGreen, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connesso',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.bluetoothService.connectedDevice?.platformName ?? 
                          'Dispositivo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _disconnectDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Disconnetti'),
                  ),
                ],
              ),
            ),

          // Lista dispositivi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.devices, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Dispositivi disponibili',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<fbp.ScanResult>>(
              stream: widget.bluetoothService.scanResults,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final result = snapshot.data![index];
                      final device = result.device;
                      final isConnected = widget.bluetoothService.connectedDevice?.remoteId == 
                                         device.remoteId;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isConnected 
                              ? Border.all(color: AppConstants.primaryGreen, width: 2)
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isConnected 
                                ? Icons.bluetooth_connected 
                                : Icons.bluetooth,
                            color: isConnected 
                                ? AppConstants.primaryGreen 
                                : Colors.grey,
                          ),
                          title: Text(
                            device.platformName.isNotEmpty 
                                ? device.platformName 
                                : 'Dispositivo sconosciuto',
                            style: TextStyle(
                              fontWeight: isConnected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            device.remoteId.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode 
                                  ? Colors.grey.shade400 
                                  : Colors.grey.shade600,
                            ),
                          ),
                          trailing: !isConnected
                              ? ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryGreen,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Connetti'),
                                )
                              : const Icon(
                                  Icons.check_circle,
                                  color: AppConstants.primaryGreen,
                                ),
                        ),
                      );
                    },
                  );
                } else if (_isScanning) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryGreen,
                    ),
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, 
                            size: 64, 
                            color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun dispositivo trovato',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scansiona'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryGreen,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}