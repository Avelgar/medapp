import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/tracker_view_model.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<FlSpot> points;
  final Color color;
  final double? maxY;
  final double normValue;
  final ChartPeriod period;

  const ChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
    required this.normValue,
    required this.period,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    double maxX = 6;
    if (period == ChartPeriod.day) maxX = 24;
    if (period == ChartPeriod.month) maxX = 29;

    double calculatedMaxY = maxY ?? 0;
    if (maxY == null) {
      double maxData = 0;
      for (var p in points) {
        if (p.y > maxData) maxData = p.y;
      }
      calculatedMaxY = (maxData > normValue ? maxData : normValue) * 1.2;
      if (calculatedMaxY == 0) calculatedMaxY = 10;
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Норма: ${normValue.toStringAsFixed(1)}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: calculatedMaxY / 5,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Colors.black12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: calculatedMaxY / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: period == ChartPeriod.month
                          ? 5
                          : (period == ChartPeriod.day ? 4 : 1),
                      getTitlesWidget: (value, meta) {
                        final valInt = value.toInt();
                        String text = '';

                        if (period == ChartPeriod.day) {
                          if (valInt >= 0 && valInt <= 24) {
                            text = '${valInt.toString().padLeft(2, '0')}:00';
                          }
                        } else {
                          int daysBack =
                              (period == ChartPeriod.month ? 29 : 6) - valInt;
                          final date = DateTime.now().subtract(
                            Duration(days: daysBack),
                          );

                          if (period == ChartPeriod.month) {
                            text = DateFormat('d MMM', 'ru').format(date);
                          } else {
                            text = DateFormat('E', 'ru').format(date);
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: calculatedMaxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: normValue,
                      color: color.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: false,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: period != ChartPeriod.month,
                      checkToShowDot: (spot, barData) => spot.y > 0,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
