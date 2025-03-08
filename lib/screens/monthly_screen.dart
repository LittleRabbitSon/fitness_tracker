import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_record.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../services/event_bus.dart';
import 'add_workout_screen.dart';

/// 本月运动记录页面
/// 
/// 显示用户当月的运动记录和统计信息
class MonthlyScreen extends StatefulWidget {
  /// 是否隐藏浮动按钮
  final bool hideFloatingButton;
  
  const MonthlyScreen({super.key, this.hideFloatingButton = false});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

/// 本月运动记录页面状态管理
class _MonthlyScreenState extends State<MonthlyScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<WorkoutRecord> _monthlyRecords = [];
  Map<String, Exercise> _exercisesMap = {};
  int _totalDuration = 0;
  int _totalWorkouts = 0;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _loadExercises().then((_) => _loadMonthlyRecords());
    
    // 监听数据更新事件，当有新记录添加或删除时刷新页面
    _subscription = eventBus.on<DataUpdatedEvent>().listen((event) {
      if (event.dataType == 'workout') {
        _loadMonthlyRecords();
      }
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel(); // 取消事件订阅，防止内存泄漏
    super.dispose();
  }
  
  @override
  void didUpdateWidget(MonthlyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMonthlyRecords(); // 当widget更新时重新加载数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMonthlyRecords(); // 当依赖变化时重新加载数据
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
        title: const Text('本月运动'),
      ),
      body: Column(
        children: [
          // 本月统计卡片
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
                            '总次数',
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
          
          // 本月记录标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '本月记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${DateTime.now().year}年${DateTime.now().month}月',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // 本月记录列表
          Expanded(
            child: _monthlyRecords.isEmpty
                ? const Center(
                    child: Text(
                      '本月还没有运动记录',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _monthlyRecords.length,
                    itemBuilder: (context, index) {
                      final workout = _monthlyRecords[index];
                      // 获取运动类型信息
                      final exercise = _exercisesMap[workout.exerciseTypeId];
                      final exerciseName = exercise?.name ?? '未知运动';
                      final exerciseIcon = exercise?.icon ?? 'fitness_center';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              _getIconData(exerciseIcon),
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            exerciseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${workout.date.year}年${workout.date.month.toString().padLeft(2, '0')}月${workout.date.day.toString().padLeft(2, '0')}日 ${workout.date.hour.toString().padLeft(2, '0')}:${workout.date.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (workout.notes != null && workout.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    workout.notes!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${workout.duration}分钟',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.hideFloatingButton
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
                ).then((value) {
                  if (value == true) {
                    _loadMonthlyRecords();
                  }
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}