import 'dart:math' as math;
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/history_stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Interactive time-series line chart for hydroponic sensor readings.
///
/// Highlights safe biological target ranges with a biophilic `brandSurface` band.
class TelemetryHistoryChart extends StatelessWidget {
  const TelemetryHistoryChart({
    required this.readings,
    required this.metric,
    required this.range,
    required this.stats,
    super.key,
  });

  final List<SensorReading> readings;
  final SensorMetric metric;
  final HistoryRange range;
  final HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.s24),
          child: Text(
            'No readings available for this period',
            style: TextStyle(color: context.ag.textSecondary),
          ),
        ),
      );
    }

    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    // Time window baseline
    final toTime = readings.last.recordedAt;
    final fromTime = toTime.subtract(range.duration);
    final totalHours = range.duration.inHours.toDouble();

    // Map readings to chronological FlSpots (X = hours elapsed from start of window)
    final spots = <FlSpot>[];
    for (final r in readings) {
      final hoursFromStart = r.recordedAt.difference(fromTime).inMinutes / 60.0;
      if (hoursFromStart >= 0 && hoursFromStart <= totalHours) {
        spots.add(FlSpot(hoursFromStart, metric.valueOf(r)));
      }
    }

    // Sort chronologically by X
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AgSpace.s16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AgRadius.all(AgRadius.r20),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s24),
            child: Text(
              'No readings recorded for this period',
              style:
                  textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    // Dynamic Y-axis scale based on data and metric targets
    final dataMin = stats.min;
    final dataMax = stats.max;
    final minY =
        math.max(0.0, math.min(dataMin, metric.targetMin) - _yPadding(metric));
    final maxY = math.max(dataMax, metric.targetMax) + _yPadding(metric);

    final xInterval = range == HistoryRange.hours24 ? 6.0 : 24.0;
    final yInterval = _yInterval(metric);

    return Container(
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target range indicator badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metric.label,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.brandSurface,
                  borderRadius: AgRadius.all(AgRadius.pill),
                  border:
                      Border.all(color: colors.brand.withValues(alpha: 0.5)),
                ),
                child: Text(
                  metric.targetLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AgSpace.s16),

          // Main Line Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: totalHours,
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                // Shaded target band representing ideal biological range
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: metric.targetMin,
                      y2: metric.targetMax,
                      color: colors.brandSurface,
                    ),
                  ],
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
                      reservedSize: 44,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value < minY || value > maxY) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            metric.format(value),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > totalHours) {
                          return const SizedBox.shrink();
                        }
                        final tickTime = fromTime
                            .add(Duration(minutes: (value * 60).round()));
                        final label = range == HistoryRange.hours24
                            ? DateFormat.Hm().format(tickTime)
                            : DateFormat.E().format(tickTime);

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            label,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: colors.text,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AgSpace.s12),

          // Divider
          Divider(color: colors.border, height: 1),

          const SizedBox(height: AgSpace.s12),

          // Stat row: Avg 6.1 · Min 5.8 · Max 6.4 · 96% in range
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AgSpace.s8),
              Expanded(
                child: Text(
                  stats.summaryLabel(metric),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _yPadding(SensorMetric metric) => switch (metric) {
        SensorMetric.ph => 0.4,
        SensorMetric.ec => 0.3,
        SensorMetric.waterTemp => 2.0,
        SensorMetric.waterLevel => 5.0,
      };

  double _yInterval(SensorMetric metric) => switch (metric) {
        SensorMetric.ph => 0.5,
        SensorMetric.ec => 0.5,
        SensorMetric.waterTemp => 4.0,
        SensorMetric.waterLevel => 25.0,
      };
}
