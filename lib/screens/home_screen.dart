import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service.dart';
import '../services/bluetooth_service.dart';
import '../services/ai_service.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../models/audio_data.dart';
import '../utils/audio_utils.dart';
import '../utils/constants.dart';
import '../widgets/audio_spectrogram.dart' as spectrogram;
import '../widgets/noise_level_display.dart' as noise;
import '../widgets/ai_recognition_card.dart' as ai;
import '../widgets/bottom_navigation_bar.dart';
import 'bluetooth_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  final BluetoothService _bluetoothService = BluetoothService();
  final AiService _aiService = AiService();
  
  final List<AudioData> _audioDataList = [];
  int _sampleCounter = 0;
  NoiseClassification? _currentClassification;
  double _currentDecibels = 0.0;
  double _thresholdDb = AppConstants.defaultThresholdDb;
  bool _adaptiveThreshold = false;
  bool _isDarkMode = false;
  bool _lastAlertSent = false;
  bool _aiInitialized = false;
  
  // Buffer per soglia adattiva
  final List<double> _recentDecibels = [];
  
  StreamSubscription? _audioSubscription;
  StreamSubscription? _rawAudioSubscription;
  StreamSubscription? _resetSubscription;
  Timer? _classificationTimer;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeAI();
    _initializeAudio();
  }
  
  Future<void> _initializeAI() async {
    _aiInitialized = await _aiService.initialize();
    if (mounted) setState(() {});
  }
  
  Future<void> _loadSettings() async {
    await SettingsService.initialize();
    setState(() {
      _thresholdDb = SettingsService.getThreshold();
      _adaptiveThreshold = SettingsService.isAdaptiveThreshold();
      _isDarkMode = SettingsService.isDarkMode();
    });
    
    // Tenta auto-connessione ESP32
    _autoConnectESP32();
  }
  
  Future<void> _autoConnectESP32() async {
    // Aspetta 3 secondi dopo l'avvio
    await Future.delayed(const Duration(seconds: 3));
    
    // Prova a connettersi automaticamente
    bool connected = await _bluetoothService.autoConnect();
    
    if (connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bluetooth_connected, color: Colors.white),
              SizedBox(width: 8),
              Text('ESP32 connesso'),
            ],
          ),
          backgroundColor: AppConstants.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _initializeAudio() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    bool hasPermission = await PermissionService.requestMicrophonePermission();
    
    if (!hasPermission) {
      if (mounted) _showPermissionDeniedDialog();
      return;
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    bool started = await _audioService.startRecording();
    
    if (started) {
      _audioSubscription = _audioService.audioStream.listen((audioData) {
        if (!mounted) return;
        setState(() {
          _currentDecibels = audioData.decibels;
          
          // Sampling: aggiungi 1 punto ogni 5
          _sampleCounter++;
          if (_sampleCounter >= AppConstants.samplingInterval) {
            _audioDataList.add(audioData);
            _sampleCounter = 0;
            
            // Mantieni solo gli ultimi maxDataPoints
            if (_audioDataList.length > AppConstants.maxDataPoints) {
              _audioDataList.removeAt(0);
            }
          }
          
          // Aggiorna buffer per soglia adattiva
          if (_adaptiveThreshold) {
            _recentDecibels.add(audioData.decibels);
            if (_recentDecibels.length > 50) {
              _recentDecibels.removeAt(0);
            }
            _updateAdaptiveThreshold();
          }
          
          // Controlla soglia e invia alert ESP32
          _checkThresholdAndAlert();
        });
      });
      
      _resetSubscription = _audioService.resetStream.listen((_) {
        if (!mounted) return;
        setState(() {
          _audioDataList.clear();
          _currentDecibels = 0.0;
          _currentClassification = null;
        });
      });
      
      // Timer per classificazione ogni 1 secondo
      _classificationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (_audioDataList.length >= 10 && mounted) {
            setState(() {
              _currentClassification = AudioUtils.classifyNoise(_audioDataList);
            });
          }
        },
      );
    }
  }
  
  void _updateAdaptiveThreshold() {
    if (_recentDecibels.isEmpty) return;
    
    // Calcola la media degli ultimi 50 campioni
    double avg = _recentDecibels.reduce((a, b) => a + b) / _recentDecibels.length;
    
    // Imposta soglia a +15dB sopra la media
    double newThreshold = (avg + 15).clamp(
      AppConstants.minThresholdDb,
      AppConstants.maxThresholdDb,
    );
    
    if ((newThreshold - _thresholdDb).abs() > 5) {
      setState(() {
        _thresholdDb = newThreshold;
      });
    }
  }
  
  void _checkThresholdAndAlert() {
    bool aboveThreshold = _currentDecibels >= _thresholdDb;
    
    // Invia alert solo quando supera la soglia (non continuamente)
    if (aboveThreshold && !_lastAlertSent) {
      _bluetoothService.sendThresholdAlert(_currentDecibels);
      _lastAlertSent = true;
    } else if (!aboveThreshold) {
      _lastAlertSent = false;
    }
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permesso negato'),
        content: const Text(
          'L\'app ha bisogno del permesso del microfono per funzionare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showSensitivityDialog() {
    double tempSensitivity = _audioService.sensitivity;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regola Sensibilità'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sensibilità: ${tempSensitivity.toStringAsFixed(1)}x'),
                Slider(
                  value: tempSensitivity,
                  min: AppConstants.minSensitivity,
                  max: AppConstants.maxSensitivity,
                  divisions: 15,
                  label: tempSensitivity.toStringAsFixed(1),
                  activeColor: AppConstants.primaryGreen,
                  onChanged: (value) {
                    setDialogState(() => tempSensitivity = value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _audioService.setSensitivity(tempSensitivity);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _resetGraph() {
    setState(() {
      _audioDataList.clear();
      _sampleCounter = 0;
      _currentDecibels = 0.0;
      _currentClassification = null;
    });
  }
  
  void _navigateToBluetooth() async {
    // Richiedi permessi Bluetooth prima di aprire la schermata
    bool hasPermissions = await PermissionService.requestBluetoothPermissions();
    
    if (!hasPermissions && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permessi Bluetooth necessari'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BluetoothScreen(
            bluetoothService: _bluetoothService,
            isDarkMode: _isDarkMode,
          ),
        ),
      );
    }
  }
  
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isDarkMode: _isDarkMode,
          onThemeChanged: (isDark) {
            setState(() => _isDarkMode = isDark);
          },
        ),
      ),
    ).then((_) {
      // Ricarica impostazioni quando si torna
      _loadSettings();
    });
  }
  
  @override
  void dispose() {
    _audioSubscription?.cancel();
    _rawAudioSubscription?.cancel();
    _resetSubscription?.cancel();
    _classificationTimer?.cancel();
    _audioService.stopRecording();
    _audioService.dispose();
    _bluetoothService.dispose();
    _aiService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode 
        ? AppConstants.darkBackgroundColor 
        : AppConstants.backgroundColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: AppConstants.headerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.primaryGreen,
                    AppConstants.darkGreen,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'PULSE APP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textDark,
                      ),
                    ),
                  ),
                  // Indicatore connessione Bluetooth
                  if (_bluetoothService.isConnected)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.bluetooth_connected,
                              size: 16,
                              color: AppConstants.primaryGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ESP32',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Contenuto scrollabile
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    spectrogram.AudioSpectrogram(
                      audioData: _audioDataList,
                      isDarkMode: _isDarkMode,
                    ),
                    noise.NoiseLevelDisplay(
                      decibels: _currentDecibels,
                      isDarkMode: _isDarkMode,
                    ),
                    ai.AiRecognitionCard(
                      classification: _currentClassification,
                      isDarkMode: _isDarkMode,
                      thresholdDb: _thresholdDb,
                      currentDb: _currentDecibels,
                      adaptiveEnabled: _adaptiveThreshold,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation
            CustomBottomNavigationBar(
              onBluetoothTap: _navigateToBluetooth,
              onHomeTap: _resetGraph,
              onSettingsTap: _navigateToSettings,
              isDarkMode: _isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}