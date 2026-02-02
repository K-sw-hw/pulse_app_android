import 'dart:math';
import '../models/audio_data.dart';

class AudioUtils {
  // Converte ampiezza in decibel
  static double amplitudeToDecibels(double amplitude, double sensitivity) {
    if (amplitude <= 0) return 0.0;
    
    // Formula per convertire ampiezza in dB
    double db = 20 * log(amplitude * sensitivity) / ln10;
    
    // Normalizza tra 0 e 120 dB
    db = db.clamp(0.0, 120.0);
    
    return db;
  }
  
  // Classifica il tipo di rumore basandosi sui dB e pattern
  static NoiseClassification classifyNoise(List<AudioData> recentData) {
    if (recentData.isEmpty) {
      return NoiseClassification(noiseType: 'Silence', confidence: 0.0);
    }
    
    // Calcola statistiche
    double avgDb = recentData.map((d) => d.decibels).reduce((a, b) => a + b) / recentData.length;
    double maxDb = recentData.map((d) => d.decibels).reduce(max);
    double variance = _calculateVariance(recentData.map((d) => d.decibels).toList());
    
    // Logica di classificazione semplificata (da migliorare con ML)
    if (avgDb < 30) {
      return NoiseClassification(noiseType: 'Silence', confidence: 0.95);
    } else if (avgDb < 50 && variance < 100) {
      return NoiseClassification(noiseType: 'Background noise', confidence: 0.85);
    } else if (avgDb >= 50 && avgDb < 70 && variance > 100) {
      return NoiseClassification(noiseType: 'Voice/Speech', confidence: 0.80);
    } else if (avgDb >= 70 && avgDb < 90) {
      return NoiseClassification(noiseType: 'Loud music', confidence: 0.75);
    } else if (avgDb >= 90) {
      return NoiseClassification(noiseType: 'Very loud noise', confidence: 0.85);
    } else if (variance > 200) {
      return NoiseClassification(noiseType: 'Variable noise', confidence: 0.70);
    } else {
      return NoiseClassification(noiseType: 'Unknown', confidence: 0.50);
    }
  }
  
  // Calcola varianza
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    num sumSquaredDiff = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b);
    return sumSquaredDiff / values.length;
  }
}