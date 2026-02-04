import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NoiseLevelDisplay extends StatelessWidget {
  final double decibels;
  final bool isDarkMode;
  
  const NoiseLevelDisplay({
    super.key,
    required this.decibels,
    this.isDarkMode = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Noise: ${decibels.toStringAsFixed(0)} dB',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}