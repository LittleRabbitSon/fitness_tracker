import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../models/workout_record.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../services/event_bus.dart';
import 'add_workout_screen.dart';

/// 周统计数据类
class WeeklyStats {
  final int weekNumber;
  final int totalDuration;
  final int workoutCount;
  
  WeeklyStats({
    required this.weekNumber,
    required this.totalDuration,
    required this.workoutCount,
  });
}

/// 统计页面
/// 
/// 显示用户的运动统计信息和图表
class StatsScreen extends StatefulWidget {
  /// 是否隐藏浮动按钮
  final bool hideFloatingButton;
  
  const StatsScreen({super.key, this.hideFloatingButton = false});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

/// 统计页面状态管理
class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<WorkoutRecord> _monthlyRecords = [];
  Map<String, Exercise> _exercisesMap = {};
  int _totalDuration = 0;
  int _totalWorkouts = 0;
  late StreamSubscription _subscription;
  
  // 周统计数据
  List<WeeklyStats> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
 
     _loadMonthlyRecords();
    _loadWeeklyStats();
    
    // 订阅数据更新事件
    _subscription = eventBus.on<DataUpdatedEvent>().listen((event) {
      if (event.dataType == 'workout') {
        _loadMonthlyRecords();
        _loadWeeklyStats();
      }
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel(); // 取消事件订阅，防止内存泄漏
    super.dispose();
  }
  
  @override
  void didUpdateWidget(StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMonthlyRecords();
    _loadWeeklyStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMonthlyRecords();
    _loadWeeklyStats();
  }

  /// 加载所有运动类型
  Future<void> _loadExercises() async {
    try {
      final exercises = await _databaseService.getAllExercises();
      setState(() {
        _exercisesMap = {for (var e in exercises) e.id: e};
      });
    } catch (e) {
      print('加载运动类型失败: $e');
    }
  }

  /// 加载本月运动记录
  Future<void> _loadMonthlyRecords() async {
    try {
      // 获取本月的开始时间（1号0点0分0秒）
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = (now.month < 12) 
          ? DateTime(now.year, now.month + 1, 0, 23, 59, 59)
          : DateTime(now.year + 1, 1, 0, 23, 59, 59);
      
      // 获取本月的所有记录
      final records = await _databaseService.getWorkoutRecordsByDateRange(
        firstDayOfMonth, 
        lastDayOfMonth
      );
      
      // 计算总时长和总记录数
      final totalDuration = records.fold<int>(0, (sum, record) => sum + record.duration);
      
      setState(() {
        _monthlyRecords = records;
        _totalDuration = totalDuration;
        _totalWorkouts = records.length;
      });
    } catch (e) {
      print('加载本月运动记录失败: $e');
    }
  }
  
  /// 加载周统计数据
  Future<void> _loadWeeklyStats() async {
    try {
      final now = DateTime.now();
      
      // 计算6周前的日期
      final sixWeeksAgo = now.subtract(const Duration(days: 42));
      
      // 获取最近6周的所有记录
      final records = await _databaseService.getWorkoutRecordsByDateRange(
        sixWeeksAgo, 
        now
      );
      
      // 按周分组记录
      final Map<int, List<WorkoutRecord>> weeklyRecords = {};
      
      // 计算当前是一年中的第几周
      int currentWeek = _getWeekNumber(now);
      
      // 初始化最近6周的数据
      for (int i = 0; i < 6; i++) {
        int weekNum = (currentWeek - i) > 0 ? (currentWeek - i) : (52 + (currentWeek - i));
        weeklyRecords[weekNum] = [];
      }
      
      // 将记录按周分组
      for (var record in records) {
        int weekNum = _getWeekNumber(record.date);
        if (weeklyRecords.containsKey(weekNum)) {
          weeklyRecords[weekNum]!.add(record);
        }
      }
      
      // 转换为周统计数据列表
      List<WeeklyStats> stats = [];
      for (int i = 0; i < 6; i++) {
        int weekNum = (currentWeek - i) > 0 ? (currentWeek - i) : (52 + (currentWeek - i));
        final weekRecords = weeklyRecords[weekNum] ?? [];
        final totalDuration = weekRecords.fold<int>(0, (sum, record) => sum + record.duration);
        
        stats.add(WeeklyStats(
          weekNumber: weekNum,
          totalDuration: totalDuration,
          workoutCount: weekRecords.length,
        ));
      }
      
      // 反转列表，使最早的周在左边
      stats = stats.reversed.toList();
      
      setState(() {
        _weeklyStats = stats;
      });
    } catch (e) {
      print('加载周统计数据失败: $e');
    }
  }
  
  /// 获取日期所在的周数（一年中的第几周）
  int _getWeekNumber(DateTime date) {
    // 计算一年中的第一天
    final firstDayOfYear = DateTime(date.year, 1, 1);
    // 计算日期是一年中的第几天
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    // 计算第一天是星期几（0是星期一，6是星期日）
    final weekdayOfFirstDay = firstDayOfYear.weekday;
    // 计算周数
    return ((dayOfYear + weekdayOfFirstDay - 1) / 7).ceil();
  }

  /// 将字符串转换为IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'sports_volleyball':
        return Icons.sports_volleyball;
      case 'hiking':
        return Icons.hiking;
      default:
        return Icons.fitness_center; // 默认图标
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动统计'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 本月统计卡片（保留不变）
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本月统计',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 总时长统计
                        Column(
                          children: [
                            Text(
                              '$_totalDuration',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              '总时长（分钟）',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        // 总次数统计
                        Column(
                          children: [
                            Text(
                              '$_totalWorkouts',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              '运动次数',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 保留第一个运动趋势卡片（原line304-333）
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '运动趋势',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _weeklyStats.isEmpty
                          ? const Center(child: Text('暂无数据'))
                          : _buildChartWithLabels(),
                    ),
                  ],
                ),
              ),
            ),

            // 删除第二个运动趋势卡片（原line336-358）
            
            // 详细记录卡片（保留不变）
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本月详细记录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _monthlyRecords.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('本月暂无运动记录'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _monthlyRecords.length,
                            itemBuilder: (context, index) {
                              final workout = _monthlyRecords[index];
                              final exercise = _exercisesMap[workout.exerciseTypeId];
                              final exerciseName = exercise?.name ?? '未知运动';
                              final exerciseIcon = exercise?.icon ?? 'fitness_center';
                              
                              // 格式化日期
                              final date = workout.date;
                              final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: Icon(
                                    _getIconData(exerciseIcon),
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(exerciseName),
                                subtitle: Text(formattedDate),
                                trailing: Text(
                                  '${workout.duration}分钟',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.hideFloatingButton
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
                ).then((result) {
                  if (result == true) {
                    _loadMonthlyRecords();
                    _loadWeeklyStats();
                  }
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }
  
  /// 构建周统计柱状图
  Widget _buildWeeklyChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blue.shade50.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipMargin: 10,
            // 确保tooltip不会超出屏幕边界
            fitInsideHorizontally: true,
            fitInsideVertically: false,
            // 将方向设置为始终在上方，但会自动调整以适应屏幕
            direction: TooltipDirection.top,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stats = _weeklyStats[groupIndex];
              // 计算该周的时间范围
              final now = DateTime.now();
              final currentWeek = _getWeekNumber(now);
              final weekDiff = currentWeek - stats.weekNumber;
              final weekStartDate = now.subtract(Duration(days: now.weekday + weekDiff * 7));
              final weekEndDate = weekStartDate.add(const Duration(days: 6));
              
              // 格式化日期
              final startDateStr = '${weekStartDate.month}月${weekStartDate.day}日';
              final endDateStr = '${weekEndDate.month}月${weekEndDate.day}日';
              
              return BarTooltipItem(
                '$startDateStr - $endDateStr\n${stats.totalDuration}分钟 · ${stats.workoutCount}次运动',
                const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // 字体大小从13减小到11
                  height: 1.3, // 行高也适当调整
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _weeklyStats.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '第${_weeklyStats[index].weekNumber}周',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: 0,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: _buildBarGroups(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
      ),
    );
  }
  
  /// 计算图表Y轴最大值
  double _calculateMaxY() {
    if (_weeklyStats.isEmpty) return 100;
    
    // 找出最大的总时长
    final maxDuration = _weeklyStats.fold<int>(
      0, 
      (max, stats) => stats.totalDuration > max ? stats.totalDuration : max
    );
    
    // 向上取整到最接近的30的倍数，并确保至少为30
    return (((maxDuration / 30).ceil() * 30) + 30).toDouble();
  }
  
  /// 构建柱状图数据组
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_weeklyStats.length, (index) {
      final duration = _weeklyStats[index].totalDuration;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: duration.toDouble(),
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            // 添加柱状图顶部标签
            rodStackItems: [
              BarChartRodStackItem(
                0, 
                duration.toDouble(), 
                Colors.transparent,
                BorderSide.none
              ),
            ],
            // 添加柱状图顶部文字
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0,
              color: Colors.transparent,
            ),
          ),
        ],
        // 添加柱状图顶部的时长标签
        showingTooltipIndicators: const [],
        barsSpace: 4,
      );
    });
  }
  
  /// 自定义绘制器，用于在柱状图上方绘制时长标签
  Widget _buildChartWithLabels() {
    // 直接返回柱状图，不再添加标签层
    return _buildWeeklyChart();
  }
} // 结束_StatsScreenState类
