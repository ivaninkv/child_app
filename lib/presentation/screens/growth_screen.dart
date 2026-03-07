import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../bloc/parameters/parameters_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';

enum ChartViewMode { height, weight, both }

const kHeightColor = Color(0xFF42A5F5);
const kWeightColor = Color(0xFF66BB6A);

class GrowthScreen extends StatefulWidget {
  final String? childId;

  const GrowthScreen({super.key, this.childId});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  ChartViewMode _viewMode = ChartViewMode.both;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId =
          widget.childId ?? context.read<AppBloc>().state.selectedChild?.id;
      if (childId != null) {
        context.read<ParametersBloc>().add(ParametersLoad(childId));
      }
    });
  }

  @override
  void didUpdateWidget(covariant GrowthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      final childId =
          widget.childId ?? context.read<AppBloc>().state.selectedChild?.id;
      if (childId != null) {
        context.read<ParametersBloc>().add(ParametersLoad(childId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Параметры развития'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<ChartViewMode>(
              segments: const [
                ButtonSegment(value: ChartViewMode.height, label: Text('Рост')),
                ButtonSegment(value: ChartViewMode.weight, label: Text('Вес')),
                ButtonSegment(value: ChartViewMode.both, label: Text('Оба')),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<ChartViewMode> selection) {
                setState(() => _viewMode = selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ParametersBloc, ParametersState>(
        builder: (context, state) {
          if (state is ParametersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ParametersLoaded) {
            if (state.parameters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.straighten, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Нет данных о параметрах'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go('/parameter/add'),
                      child: const Text('Добавить замер'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (state.latestHeight != null || state.latestWeight != null)
                  _buildLatestStats(state),
                Expanded(child: _buildChart(state.parameters)),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/parameter/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLatestStats(ParametersLoaded state) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (state.latestHeight != null)
              _buildStatItem(
                'Рост',
                '${state.latestHeight!.height} см',
                Icons.height,
              ),
            if (state.latestWeight != null)
              _buildStatItem(
                'Вес',
                '${state.latestWeight!.weight} кг',
                Icons.monitor_weight,
              ),
            if (state.latestShoeSize != null)
              _buildStatItem(
                'Размер ноги',
                state.latestShoeSize!.shoeSize.toString(),
                Icons.sports_handball,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildChart(List<Parameter> parameters) {
    final filtered = parameters.where((p) {
      if (_viewMode == ChartViewMode.height) return p.height != null;
      if (_viewMode == ChartViewMode.weight) return p.weight != null;
      return p.height != null || p.weight != null;
    }).toList();
    filtered.sort((a, b) => a.date.compareTo(b.date));

    if (filtered.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final hasHeight = filtered.any((p) => p.height != null);
    final hasWeight = filtered.any((p) => p.weight != null);

    if (_viewMode == ChartViewMode.both) {
      final charts = <Widget>[];
      if (hasHeight) {
        charts.add(Expanded(child: _buildHeightChart(filtered)));
      }
      if (hasHeight && hasWeight) {
        charts.add(const SizedBox(height: 16));
      }
      if (hasWeight) {
        charts.add(Expanded(child: _buildWeightChart(filtered)));
      }
      return Column(children: charts);
    }

    if (_viewMode == ChartViewMode.height) {
      if (!hasHeight) {
        return const Center(child: Text('Нет данных о росте'));
      }
      return _buildHeightChart(filtered);
    }

    if (_viewMode == ChartViewMode.weight) {
      if (!hasWeight) {
        return const Center(child: Text('Нет данных о весе'));
      }
      return _buildWeightChart(filtered);
    }

    return const SizedBox();
  }

  Widget _buildHeightChart(List<Parameter> filtered) {
    final heightSpots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      if (filtered[i].height != null) {
        heightSpots.add(FlSpot(i.toDouble(), filtered[i].height!));
      }
    }

    if (heightSpots.isEmpty) {
      return const Center(child: Text('Нет данных о росте'));
    }

    final minY = heightSpots.map((p) => p.y).reduce(math.min) - 10;
    final maxY = heightSpots.map((p) => p.y).reduce(math.max) + 10;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Дата',
                style: TextStyle(fontSize: 12),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < filtered.length) {
                    final date = filtered[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.month}/${date.year % 100}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Рост (см)',
                style: TextStyle(fontSize: 12),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 10,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          minX: 0,
          maxX: (filtered.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: heightSpots,
              isCurved: true,
              color: kHeightColor,
              barWidth: 3,
              dotData: FlDotData(
                show: false,
                checkToShowDot: (spot, barData) =>
                    _touchedIndex == spot.x.toInt(),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    kHeightColor.withValues(alpha: 0.3),
                    kHeightColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              if (response != null && response.lineBarSpots != null) {
                setState(() {
                  _touchedIndex = response.lineBarSpots!.first.x.toInt();
                });
              } else {
                setState(() {
                  _touchedIndex = null;
                });
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final index = touchedSpots.first.x.toInt();
                if (index >= filtered.length) return [];
                final date = filtered[index].date;
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Рост: ${spot.y.toInt()} см\n${date_utils.DateUtils.formatDateShort(date)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildWeightChart(List<Parameter> filtered) {
    final weightSpots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      if (filtered[i].weight != null) {
        weightSpots.add(FlSpot(i.toDouble(), filtered[i].weight!));
      }
    }

    if (weightSpots.isEmpty) {
      return const Center(child: Text('Нет данных о весе'));
    }

    final minY = weightSpots.map((p) => p.y).reduce(math.min) - 2;
    final maxY = weightSpots.map((p) => p.y).reduce(math.max) + 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Дата',
                style: TextStyle(fontSize: 12),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < filtered.length) {
                    final date = filtered[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.month}/${date.year % 100}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Вес (кг)',
                style: TextStyle(fontSize: 12),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 5,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          minX: 0,
          maxX: (filtered.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: weightSpots,
              isCurved: true,
              color: kWeightColor,
              barWidth: 3,
              dotData: FlDotData(
                show: false,
                checkToShowDot: (spot, barData) =>
                    _touchedIndex == spot.x.toInt(),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    kWeightColor.withValues(alpha: 0.3),
                    kWeightColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              if (response != null && response.lineBarSpots != null) {
                setState(() {
                  _touchedIndex = response.lineBarSpots!.first.x.toInt();
                });
              } else {
                setState(() {
                  _touchedIndex = null;
                });
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final index = touchedSpots.first.x.toInt();
                if (index >= filtered.length) return [];
                final date = filtered[index].date;
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Вес: ${spot.y.toStringAsFixed(1)} кг\n${date_utils.DateUtils.formatDateShort(date)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}
