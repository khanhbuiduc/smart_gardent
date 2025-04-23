import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _daily24HData = [];
  List<Map<String, dynamic>> _weeklyData = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final daily = await _firebaseService.getDataLast24Hours();
      final weekly = await _firebaseService.getWeeklyAverages();

      setState(() {
        _daily24HData = daily;
        _weeklyData = weekly;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Phân Tích Dữ Liệu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '24 Giờ Qua'),
            Tab(text: 'Tuần Qua'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _build24HourView(),
                _buildWeeklyView(),
              ],
            ),
    );
  }

  Widget _build24HourView() {
    if (_daily24HData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu trong 24 giờ qua'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu Đồ Nhiệt Độ (°C)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(_daily24HData, 'temperature', Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            'Biểu Đồ Độ Ẩm Không Khí (%)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(_daily24HData, 'humidity', Colors.blue),
          ),
          const SizedBox(height: 24),
          Text(
            'Biểu Đồ Độ Ẩm Đất (%)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child:
                _buildLineChart(_daily24HData, 'soil_moisture', Colors.brown),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    if (_weeklyData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu trong tuần qua'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhiệt Độ Trung Bình (°C)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildBarChart(_weeklyData, 'avg_temperature', Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            'Độ Ẩm Không Khí Trung Bình (%)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildBarChart(_weeklyData, 'avg_humidity', Colors.blue),
          ),
          const SizedBox(height: 24),
          Text(
            'Độ Ẩm Đất Trung Bình (%)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child:
                _buildBarChart(_weeklyData, 'avg_soil_moisture', Colors.brown),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
      List<Map<String, dynamic>> data, String field, Color color) {
    final spots = data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return FlSpot(i.toDouble(), double.tryParse(item[field].toString()) ?? 0);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const Text('');
                if (value.toInt() >= data.length) return const Text('');
                final timestamp = data[value.toInt()]['timestamp'] as DateTime;
                return Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: color.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      List<Map<String, dynamic>> data, String field, Color color) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(data, field) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const Text('');
                final date = data[value.toInt()]['date'] as String;
                final dayOfMonth = date.split('-')[2];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(dayOfMonth, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: double.tryParse(item[field].toString()) ?? 0,
                color: color,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _getMaxValue(List<Map<String, dynamic>> data, String field) {
    double max = 0;
    for (var item in data) {
      final value = double.tryParse(item[field].toString()) ?? 0;
      if (value > max) max = value;
    }
    return max;
  }
}
