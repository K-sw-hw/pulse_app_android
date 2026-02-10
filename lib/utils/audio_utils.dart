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
  
  // Calcola varianza
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    num sumSquaredDiff = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b);
    return sumSquaredDiff / values.length;
  }
}