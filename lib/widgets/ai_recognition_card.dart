import 'package:flutter/material.dart';
import '../models/audio_data.dart';
import '../utils/constants.dart';

class AiRecognitionCard extends StatelessWidget {
  final NoiseClassification? classification;
  final bool isDarkMode;
  final double thresholdDb;
  final double currentDb;
  final bool adaptiveEnabled;
  
  const AiRecognitionCard({
    super.key,
    this.classification,
    this.isDarkMode = false,
    this.thresholdDb = 80.0,
    this.currentDb = 0.0,
    this.adaptiveEnabled = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode 
        ? AppConstants.darkCardColor 
        : Colors.white;
    final textColor = isDarkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;
    final subtextColor = isDarkMode 
        ? Colors.grey.shade400 
        : Colors.grey.shade600;
    
    final bool aboveThreshold = currentDb >= thresholdDb;
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppConstants.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI: Noise recognition',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              // Indicatore soglia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aboveThreshold 
                      ? Colors.red.shade100 
                      : (adaptiveEnabled 
                          ? AppConstants.primaryGreen.withValues(alpha: 0.2)
                          : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      adaptiveEnabled ? Icons.auto_fix_high : Icons.tune,
                      size: 16,
                      color: aboveThreshold 
                          ? Colors.red 
                          : (adaptiveEnabled 
                              ? AppConstants.primaryGreen 
                              : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${thresholdDb.toStringAsFixed(0)} dB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: aboveThreshold 
                            ? Colors.red 
                            : (adaptiveEnabled 
                                ? AppConstants.primaryGreen 
                                : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: AppConstants.aiCardHeight,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(
                color: aboveThreshold 
                    ? Colors.red.shade300 
                    : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                width: aboveThreshold ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (aboveThreshold)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning_amber, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ Rumore pericoloso!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (classification == null)
                  Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtextColor,
                    ),
                  )
                else ...[
                  Text(
                    classification!.noiseType,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confidence: ${(classification!.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: classification!.confidence,
                    backgroundColor: isDarkMode 
                        ? Colors.grey.shade700 
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryGreen,
                    ),
                    minHeight: 8,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}