import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _threshold;
  late bool _adaptiveThreshold;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _threshold = SettingsService.getThreshold();
      _adaptiveThreshold = SettingsService.isAdaptiveThreshold();
      _darkMode = widget.isDarkMode;
    });
  }

  Future<void> _saveThreshold(double value) async {
    await SettingsService.setThreshold(value);
    setState(() => _threshold = value);
  }

  Future<void> _saveAdaptiveThreshold(bool value) async {
    await SettingsService.setAdaptiveThreshold(value);
    setState(() => _adaptiveThreshold = value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    await SettingsService.setDarkMode(value);
    setState(() => _darkMode = value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _darkMode 
        ? AppConstants.darkBackgroundColor 
        : AppConstants.backgroundColor;
    final cardColor = _darkMode 
        ? AppConstants.darkCardColor 
        : Colors.white;
    final textColor = _darkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tema
          _buildSection(
            'Aspetto',
            cardColor,
            textColor,
            [
              SwitchListTile(
                title: Text('Tema scuro', style: TextStyle(color: textColor)),
                subtitle: Text(
                  'Attiva la modalità scura',
                  style: TextStyle(
                    color: _darkMode 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                  ),
                ),
                value: _darkMode,
                activeColor: AppConstants.primaryGreen,
                onChanged: _toggleDarkMode,
                secondary: Icon(
                  _darkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppConstants.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Soglia rumore
          _buildSection(
            'Allarme Rumore',
            cardColor,
            textColor,
            [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Soglia di allarme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_threshold.toStringAsFixed(0)} dB',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invia segnale a ESP32 quando il rumore supera questa soglia',
                      style: TextStyle(
                        fontSize: 13,
                        color: _darkMode 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _threshold,
                      min: AppConstants.minThresholdDb,
                      max: AppConstants.maxThresholdDb,
                      divisions: 14,
                      label: '${_threshold.toStringAsFixed(0)} dB',
                      activeColor: AppConstants.primaryGreen,
                      onChanged: _saveThreshold,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppConstants.minThresholdDb.toInt()} dB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${AppConstants.maxThresholdDb.toInt()} dB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(
                  'Soglia adattiva',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  'Adatta automaticamente la soglia al rumore ambientale',
                  style: TextStyle(
                    color: _darkMode 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                  ),
                ),
                value: _adaptiveThreshold,
                activeColor: AppConstants.primaryGreen,
                onChanged: _saveAdaptiveThreshold,
                secondary: const Icon(
                  Icons.auto_fix_high,
                  color: AppConstants.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info
          _buildSection(
            'Informazioni',
            cardColor,
            textColor,
            [
              ListTile(
                leading: const Icon(Icons.info, color: AppConstants.primaryGreen),
                title: Text('Versione', style: TextStyle(color: textColor)),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: _darkMode 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.developer_mode, 
                    color: AppConstants.primaryGreen),
                title: Text('ESP32 Integration', style: TextStyle(color: textColor)),
                subtitle: Text(
                  'Supporto Bluetooth Low Energy',
                  style: TextStyle(
                    color: _darkMode 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    Color cardColor,
    Color textColor,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryGreen,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}