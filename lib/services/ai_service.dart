import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/audio_data.dart';

class AiService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // YAMNet richiede 0.975 secondi di audio a 16kHz = 15600 samples
  static const int _inputSize = 15600;
  final List<double> _audioBuffer = [];

  bool get isInitialized => _isInitialized;

  // Inizializza TFLite
  Future<bool> initialize() async {
    try {
      // Carica il modello
      _interpreter = await Interpreter.fromAsset('assets/models/yamnet.tflite');

      // Carica le label
      final labelData = await rootBundle.loadString('assets/models/yamnet_labels.txt');
      _labels = labelData.split('\n').where((l) => l.trim().isNotEmpty).toList();

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  // Aggiungi dati audio e analizza
  NoiseClassification? addAudioData(Uint8List rawData) {
    if (!_isInitialized || _interpreter == null) return null;

    // Converti PCM16 in float normalizzato [-1, 1]
    for (int i = 0; i < rawData.length - 1; i += 2) {
      int sample = (rawData[i + 1] << 8) | rawData[i];
      if (sample > 32767) sample -= 65536;
      _audioBuffer.add(sample / 32768.0);
    }

    // Se abbiamo abbastanza dati, esegui inferenza
    if (_audioBuffer.length >= _inputSize) {
      final result = _runInference();

      // Rimuovi i dati processati (tieni overlap del 50%)
      if (_audioBuffer.length > _inputSize ~/ 2) {
        _audioBuffer.removeRange(0, _inputSize ~/ 2);
      } else {
        _audioBuffer.clear();
      }

      return result;
    }

    return null;
  }

  // Esegui inferenza
  NoiseClassification? _runInference() {
    try {
      // Prendi gli ultimi 15600 campioni
      final inputData = _audioBuffer.sublist(
        _audioBuffer.length - _inputSize,
        _audioBuffer.length,
      );

      // Input: [1, 15600]
      final input = [Float32List.fromList(inputData)];

      // Output: [1, 521] (521 classi)
      final output = [List<double>.filled(521, 0.0)];

      // Run model
      _interpreter!.run(input, output);

      // Trova top 3 classi
      final scores = output[0];
      List<MapEntry<int, double>> indexed = [];
      for (int i = 0; i < scores.length; i++) {
        indexed.add(MapEntry(i, scores[i]));
      }
      indexed.sort((a, b) => b.value.compareTo(a.value));

      final top3 = indexed.take(3).toList();

      // Crea risultato
      String topLabel = top3[0].key < _labels.length 
          ? _labels[top3[0].key] 
          : 'Unknown';
      double topConfidence = top3[0].value;

      List<MapEntry<String, double>> topLabels = top3.map((e) {
        String label = e.key < _labels.length ? _labels[e.key] : 'Unknown';
        return MapEntry(label, e.value);
      }).toList();

      return NoiseClassification(
        noiseType: topLabel,
        confidence: topConfidence,
        topLabels: topLabels,
      );
    } catch (e) {
      return null;
    }
  }

  // Pulisci buffer
  void clearBuffer() {
    _audioBuffer.clear();
  }

  // Rilascia risorse
  void dispose() {
    _interpreter?.close();
    _audioBuffer.clear();
  }
}