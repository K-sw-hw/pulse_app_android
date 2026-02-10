import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/audio_data.dart';
import '../utils/constants.dart';

class AudioSpectrogram extends StatelessWidget {
  final List<AudioData> audioData;
  final bool isDarkMode;
  
  const AudioSpectrogram({
    super.key,
    required this.audioData,
    this.isDarkMode = false,
  });

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenSpectrogram(
          audioData: audioData,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;
    final lineColor = isDarkMode 
        ? AppConstants.darkGraphLine 
        : AppConstants.graphLine;
    
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        height: AppConstants.graphHeight,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppConstants.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.graphic_eq, color: AppConstants.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'SPECTROGRAM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.fullscreen,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: audioData.isEmpty
                  ? Center(
                      child: Text(
                        'In ascolto...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : _buildChart(lineColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Color lineColor) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: audioData.length.toDouble(),
        minY: 0,
        maxY: 120,
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            curveSmoothness: 0.4,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.3),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(enabled: false),
      ),
    );
  }
  
  List<FlSpot> _generateSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < audioData.length; i++) {
      spots.add(FlSpot(i.toDouble(), audioData[i].decibels));
    }
    return spots;
  }
}

// Schermata fullscreen orizzontale
class FullscreenSpectrogram extends StatefulWidget {
  final List<AudioData> audioData;
  final bool isDarkMode;

  const FullscreenSpectrogram({
    super.key,
    required this.audioData,
    required this.isDarkMode,
  });

  @override
  State<FullscreenSpectrogram> createState() => _FullscreenSpectrogramState();
}

class _FullscreenSpectrogramState extends State<FullscreenSpectrogram> {
  @override
  void initState() {
    super.initState();
    // Forza orientamento orizzontale
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Nascondi status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Ripristina orientamento verticale
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Mostra status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode 
        ? AppConstants.darkBackgroundColor 
        : AppConstants.backgroundColor;
    final lineColor = widget.isDarkMode 
        ? AppConstants.darkGraphLine 
        : AppConstants.graphLine;
    final textColor = widget.isDarkMode 
        ? AppConstants.darkTextColor 
        : AppConstants.textDark;

    // Calcola statistiche
    double currentDb = widget.audioData.isNotEmpty 
        ? widget.audioData.last.decibels 
        : 0;
    double avgDb = widget.audioData.isNotEmpty
        ? widget.audioData.map((d) => d.decibels).reduce((a, b) => a + b) / 
          widget.audioData.length
        : 0;
    double maxDb = widget.audioData.isNotEmpty
        ? widget.audioData.map((d) => d.decibels).reduce((a, b) => a > b ? a : b)
        : 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Grafico a tutto schermo
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header con statistiche
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Corrente
                      _buildStatCard(
                        'CORRENTE',
                        '${currentDb.toStringAsFixed(0)} dB',
                        AppConstants.primaryGreen,
                        textColor,
                      ),
                      // Media
                      _buildStatCard(
                        'MEDIA',
                        '${avgDb.toStringAsFixed(0)} dB',
                        Colors.orange,
                        textColor,
                      ),
                      // Massimo
                      _buildStatCard(
                        'MASSIMO',
                        '${maxDb.toStringAsFixed(0)} dB',
                        Colors.red,
                        textColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grafico
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 20,
                          verticalInterval: 10,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withValues(alpha: 0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} dB',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 10,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        minX: 0,
                        maxX: widget.audioData.length.toDouble(),
                        minY: 0,
                        maxY: 120,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateSpots(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: lineColor,
                            barWidth: 4,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: lineColor,
                                  strokeWidth: 0,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  lineColor.withValues(alpha: 0.4),
                                  lineColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(0)} dB',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Pulsante chiudi
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: textColor,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < widget.audioData.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.audioData[i].decibels));
    }
    return spots;
  }
}