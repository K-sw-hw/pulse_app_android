import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_data.dart';
import '../utils/constants.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _updateTimer;
  Timer? _resetTimer;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  
  bool _isRecording = false;
  double _sensitivity = AppConstants.defaultSensitivity;
  final Random _random = Random();
  double _lastDecibels = 30.0;
  
  // Stream per i dati audio
  final StreamController<AudioData> _audioStreamController = StreamController<AudioData>.broadcast();
  Stream<AudioData> get audioStream => _audioStreamController.stream;
  
  // Stream per reset
  final StreamController<void> _resetStreamController = StreamController<void>.broadcast();
  Stream<void> get resetStream => _resetStreamController.stream;
  
  bool get isRecording => _isRecording;
  double get sensitivity => _sensitivity;
  
  // Inizia la registrazione audio
  Future<bool> startRecording() async {
    try {
      // Verifica prima se ha il permesso
      bool hasPermission = await _recorder.hasPermission();
      
      if (!hasPermission) {
        return false;
      }
      
      // Aspetta un attimo per sicurezza
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Avvia lo stream audio
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      
      _isRecording = true;
      
      // Ascolta lo stream audio
      _audioStreamSubscription = stream.listen((audioData) {
        _processAudioData(audioData);
      });
      
      _startResetTimer();
      return true;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }
  
  // Processa i dati audio raw
  void _processAudioData(Uint8List data) {
    if (data.isEmpty) return;
    
    // Converti bytes in valori PCM 16-bit
    List<int> samples = [];
    for (int i = 0; i < data.length - 1; i += 2) {
      int sample = (data[i + 1] << 8) | data[i];
      // Converti in signed int
      if (sample > 32767) sample -= 65536;
      samples.add(sample);
    }
    
    if (samples.isEmpty) return;
    
    // Calcola RMS (Root Mean Square)
    double sum = 0;
    for (int sample in samples) {
      sum += sample * sample;
    }
    double rms = sqrt(sum / samples.length);
    
    // Normalizza RMS (range 0-32768) a decibel
    // Formula: dB = 20 * log10(rms / reference)
    double db;
    if (rms > 0) {
      // Normalizza su scala 0-120 dB
      db = 20 * log(rms / 100) / ln10;
      db = db.clamp(-20.0, 100.0) + 20; // Shift per avere range 0-120
    } else {
      db = 20.0; // Silenzio
    }
    
    // Applica sensibilità
    db = (db * _sensitivity).clamp(0.0, 120.0);
    
    // Smoothing per evitare salti bruschi
    _lastDecibels = (_lastDecibels * 0.7) + (db * 0.3);
    
    // Aggiungi piccola variazione naturale
    _lastDecibels += (_random.nextDouble() - 0.5) * 2;
    _lastDecibels = _lastDecibels.clamp(0.0, 120.0);
    
    _audioStreamController.add(
      AudioData(
        decibels: _lastDecibels,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  // Ferma la registrazione
  Future<void> stopRecording() async {
    try {
      await _audioStreamSubscription?.cancel();
      await _recorder.stop();
      _isRecording = false;
      _updateTimer?.cancel();
      _resetTimer?.cancel();
    } catch (e) {
      // Gestione errore silenzioso
    }
  }
  
  // Timer per resettare ogni 30 secondi
  void _startResetTimer() {
    _resetTimer = Timer.periodic(
      const Duration(seconds: AppConstants.resetIntervalSeconds),
      (timer) {
        _resetStreamController.add(null);
      },
    );
  }
  
  // Imposta sensibilità
  void setSensitivity(double newSensitivity) {
    _sensitivity = newSensitivity.clamp(
      AppConstants.minSensitivity,
      AppConstants.maxSensitivity,
    );
  }
  
  // Reset manuale
  void manualReset() {
    _resetStreamController.add(null);
  }
  
  // Pulizia
  void dispose() {
    _audioStreamSubscription?.cancel();
    _updateTimer?.cancel();
    _resetTimer?.cancel();
    _audioStreamController.close();
    _resetStreamController.close();
    _recorder.dispose();
  }
}