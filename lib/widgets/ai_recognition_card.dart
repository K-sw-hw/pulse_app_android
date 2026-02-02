import 'package:flutter/material.dart';
import '../models/audio_data.dart';
import '../utils/constants.dart';

class AiRecognitionCard extends StatelessWidget {
  final NoiseClassification? classification;
  
  const AiRecognitionCard({
    Key? key,
    this.classification,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppConstants.primaryGreen,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI: Noise recognition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
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
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: classification == null
                ? const Center(
                    child: Text(
                      'Listening...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        classification!.noiseType,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Confidence: ${(classification!.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: classification!.confidence,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryGreen,
                        ),
                        minHeight: 8,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}