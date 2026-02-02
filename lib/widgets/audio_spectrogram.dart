import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/audio_data.dart';
import '../utils/constants.dart';

class AudioSpectrogram extends StatelessWidget {
  final List<AudioData> audioData;
  
  const AudioSpectrogram({
    super.key,
    required this.audioData,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.graphHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'SPECTROGRAM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: audioData.isEmpty
                ? const Center(child: Text('Waiting for audio data...'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: audioData.length.toDouble(),
                      minY: 0,
                      maxY: AppConstants.maxDecibels,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateSpots(),
                          isCurved: true,
                          color: AppConstants.graphLine,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppConstants.graphLine,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      lineTouchData: LineTouchData(enabled: false),
                    ),
                  ),
          ),
        ],
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