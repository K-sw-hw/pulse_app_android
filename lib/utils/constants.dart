import 'package:flutter/material.dart';

class AppConstants {
  // Colori Light Theme
  static const Color primaryGreen = Color(0xFF4ECDC4);
  static const Color darkGreen = Color(0xFF2DB5AC);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF000000);
  static const Color graphLine = Color(0xFF000000);
  
  // Colori Dark Theme
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkGraphLine = Color(0xFF4ECDC4);
  
  // Dimensioni
  static const double headerHeight = 100.0;
  static const double bottomBarHeight = 80.0;
  static const double graphHeight = 250.0;
  static const double aiCardHeight = 200.0;
  
  // Audio settings
  static const int updateIntervalMs = 100;
  static const int resetIntervalSeconds = 30;
  static const double minDecibels = 0.0;
  static const double maxDecibels = 120.0;
  static const double defaultSensitivity = 1.0;
  static const double minSensitivity = 0.5;
  static const double maxSensitivity = 2.0;
  
  // Grafico
  static const int maxDataPoints = 50; // 5 secondi con sampling ogni 100ms
  static const int samplingInterval = 5; // Prendi 1 punto ogni 5
  
  // Threshold settings
  static const double defaultThresholdDb = 80.0;
  static const double minThresholdDb = 40.0;
  static const double maxThresholdDb = 110.0;
  
  // SharedPreferences keys
  static const String keyThreshold = 'threshold_db';
  static const String keyAdaptiveThreshold = 'adaptive_threshold';
  static const String keyDarkMode = 'dark_mode';
  static const String keyConnectedDeviceId = 'connected_device_id';
}