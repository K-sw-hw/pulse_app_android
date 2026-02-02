import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service.dart';
import '../services/permission_service.dart';
import '../models/audio_data.dart';
import '../utils/audio_utils.dart';
import '../utils/constants.dart';
import '../widgets/audio_spectrogram.dart' as spectrogram;
import '../widgets/noise_level_display.dart' as noise;
import '../widgets/ai_recognition_card.dart' as ai;
import '../widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  final List<AudioData> _audioDataList = [];
  NoiseClassification? _currentClassification;
  double _currentDecibels = 0.0;
  
  StreamSubscription? _audioSubscription;
  StreamSubscription? _resetSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }
  
  Future<void> _initializeAudio() async {
    // Richiedi permessi
    bool hasPermission = await PermissionService.requestMicrophonePermission();
    
    if (!hasPermission) {
      _showPermissionDeniedDialog();
      return;
    }
    
    // Avvia registrazione
    bool started = await _audioService.startRecording();
    
    if (started) {
      // Ascolta i dati audio
      _audioSubscription = _audioService.audioStream.listen((audioData) {
        setState(() {
          _audioDataList.add(audioData);
          _currentDecibels = audioData.decibels;
          
          // Mantieni solo gli ultimi 300 punti (30 secondi)
          if (_audioDataList.length > AppConstants.maxDataPoints) {
            _audioDataList.removeAt(0);
          }
          
          // Classifica il rumore ogni 10 punti
          if (_audioDataList.length % 10 == 0) {
            _currentClassification = AudioUtils.classifyNoise(_audioDataList);
          }
        });
      });
      
      // Ascolta i reset automatici
      _resetSubscription = _audioService.resetStream.listen((_) {
        setState(() {
          _audioDataList.clear();
          _currentDecibels = 0.0;
          _currentClassification = null;
        });
      });
    }
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permesso negato'),
        content: const Text(
          'L\'app ha bisogno del permesso del microfono per funzionare. '
          'Vai nelle impostazioni per abilitarlo.',
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
                    setDialogState(() {
                      tempSensitivity = value;
                    });
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
      _currentDecibels = 0.0;
      _currentClassification = null;
    });
  }
  
  @override
  void dispose() {
    _audioSubscription?.cancel();
    _resetSubscription?.cancel();
    _audioService.stopRecording();
    _audioService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
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
              child: const Center(
                child: Text(
                  'PULSE APP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
            ),
            
            // Contenuto scrollabile
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Spectrogram
                    spectrogram.AudioSpectrogram(audioData: _audioDataList),
                    
                    // Noise level
                    noise.NoiseLevelDisplay(decibels: _currentDecibels),
                    
                    // AI Recognition
                    ai.AiRecognitionCard(classification: _currentClassification),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation
            CustomBottomNavigationBar(
              onBluetoothTap: () {
                // Funzionalità Bluetooth (da implementare)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bluetooth (non implementato)')),
                );
              },
              onHomeTap: _resetGraph,
              onSettingsTap: _showSensitivityDialog,
            ),
          ],
        ),
      ),
    );
  }
}