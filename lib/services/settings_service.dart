import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsService {
  static SharedPreferences? _prefs;

  // Inizializza SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Threshold dB
  static double getThreshold() {
    return _prefs?.getDouble(AppConstants.keyThreshold) ?? 
           AppConstants.defaultThresholdDb;
  }

  static Future<void> setThreshold(double value) async {
    await _prefs?.setDouble(AppConstants.keyThreshold, value);
  }

  // Adaptive Threshold
  static bool isAdaptiveThreshold() {
    return _prefs?.getBool(AppConstants.keyAdaptiveThreshold) ?? false;
  }

  static Future<void> setAdaptiveThreshold(bool value) async {
    await _prefs?.setBool(AppConstants.keyAdaptiveThreshold, value);
  }

  // Dark Mode
  static bool isDarkMode() {
    return _prefs?.getBool(AppConstants.keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(AppConstants.keyDarkMode, value);
  }

  // Connected Device ID
  static String? getConnectedDeviceId() {
    return _prefs?.getString(AppConstants.keyConnectedDeviceId);
  }

  static Future<void> setConnectedDeviceId(String? id) async {
    if (id == null) {
      await _prefs?.remove(AppConstants.keyConnectedDeviceId);
    } else {
      await _prefs?.setString(AppConstants.keyConnectedDeviceId, id);
    }
  }
}