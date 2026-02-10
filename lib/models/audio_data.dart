class AudioData {
  final double decibels;
  final DateTime timestamp;
  
  AudioData({
    required this.decibels,
    required this.timestamp,
  });
  
  // Copia con modifiche
  AudioData copyWith({
    double? decibels,
    DateTime? timestamp,
    
  }) {
    return AudioData(
      decibels: decibels ?? this.decibels,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class NoiseClassification {
  final String noiseType;
  final double confidence;
  final List<MapEntry<String, double>> topLabels;

  NoiseClassification({
    required this.noiseType,
    required this.confidence,
    required this.topLabels,

  });
}