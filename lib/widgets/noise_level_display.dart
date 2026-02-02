import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NoiseLevelDisplay extends StatelessWidget {
  final double decibels;
  
  const NoiseLevelDisplay({
    Key? key,
    required this.decibels,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Noise: ${decibels.toStringAsFixed(0)} dB',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.textDark,
        ),
      ),
    );
  }
}