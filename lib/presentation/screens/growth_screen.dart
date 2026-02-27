import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../bloc/parameters/parameters_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final childId = context.read<AppBloc>().state.selectedChild?.id;
    if (childId != null) {
      context.read<ParametersBloc>().add(ParametersLoad(childId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Параметры развития'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Рост'),
            Tab(text: 'Вес'),
          ],
        ),
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChart(state.parameters, true),
                      _buildChart(state.parameters, false),
                    ],
                  ),
                ),
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

  Widget _buildChart(List<Parameter> parameters, bool isHeight) {
    final dataPoints = <FlSpot>[];

    final filtered = parameters
        .where((p) => isHeight ? p.height != null : p.weight != null)
        .toList();
    filtered.sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < filtered.length; i++) {
      final value = isHeight ? filtered[i].height! : filtered[i].weight!;
      dataPoints.add(FlSpot(i.toDouble(), value));
    }

    if (dataPoints.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final minY =
        dataPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b) - 10;
    final maxY =
        dataPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b) + 10;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < filtered.length) {
                    final date = filtered[value.toInt()].date;
                    return Text('${date.month}/${date.year % 100}');
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString()),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: isHeight ? Colors.blue : Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: (isHeight ? Colors.blue : Colors.green).withAlpha(50),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = filtered[index].date;
                  return LineTooltipItem(
                    '${isHeight ? "Рост" : "Вес"}: ${spot.y}${isHeight ? " см" : " кг"}\n${date.day}.${date.month}.${date.year}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
