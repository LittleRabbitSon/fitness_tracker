import 'package:flutter/material.dart';
import 'dart:async'; // 添加这一行导入 StreamSubscription 类
import '../models/workout_record.dart';
import '../models/exercise.dart'; // 添加导入
import '../services/database_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // 添加导入
import '../services/event_bus.dart'; // 添加导入

/// 运动历史记录页面
/// 
/// 显示用户所有的运动记录，按月份和日期分组，支持滑动删除功能
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// 运动历史记录页面状态管理
class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  // 按月份和日期分组的运动记录
  Map<String, Map<String, List<WorkoutRecord>>> _groupedByMonthRecords = {};
  // 运动类型映射表
  Map<String, Exercise> _exercisesMap = {};
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _loadExercises().then((_) => _loadWorkoutRecords());
    
    // 监听数据更新事件，当有新记录添加或删除时刷新页面
    _subscription = eventBus.on<DataUpdatedEvent>().listen((event) {
      if (event.dataType == 'workout') {
        _loadWorkoutRecords();  // 修改这里，使用正确的方法名
      }
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel(); // 取消事件订阅，防止内存泄漏
    super.dispose();
  }
  
  @override
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadWorkoutRecords(); // 当widget更新时重新加载数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorkoutRecords(); // 当依赖变化时重新加载数据
  }
  
  /// 加载所有运动记录并按月份和日期分组
  Future<void> _loadWorkoutRecords() async {
    try {
      final records = await _databaseService.getAllWorkoutRecords();
      
      // 首先按月份分组
      final Map<String, Map<String, List<WorkoutRecord>>> groupedByMonth = {};
      
      for (var record in records) {
        // 月份键: 2023-03
        final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
        
        // 日期键: 2023-03-15
        final dateKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
        
        // 确保月份键存在
        if (!groupedByMonth.containsKey(monthKey)) {
          groupedByMonth[monthKey] = {};
        }
        
        // 确保日期键存在
        if (!groupedByMonth[monthKey]!.containsKey(dateKey)) {
          groupedByMonth[monthKey]![dateKey] = [];
        }
        
        // 添加记录到对应日期
        groupedByMonth[monthKey]![dateKey]!.add(record);
      }
      
      // 更新状态
      setState(() {
        _groupedByMonthRecords = groupedByMonth;
      });
    } catch (e) {
      print('加载运动记录失败: $e');
    }
  }
  
  /// 确认删除对话框
  void _confirmDelete(String workoutId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条运动记录吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteWorkout(workoutId);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  /// 删除运动记录
  Future<void> _deleteWorkout(String workoutId) async {
    try {
      await _databaseService.deleteWorkoutRecord(workoutId);
      
      // 发送数据更新事件，通知其他页面刷新
      eventBus.fire(DataUpdatedEvent('workout'));
      
      // 重新加载数据
      _loadWorkoutRecords();
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      }
    } catch (e) {
      print('删除运动记录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
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
  
  /// 获取星期几的中文表示
  String _getWeekdayInChinese(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    // DateTime的weekday是1-7，其中1是周一，7是周日
    return weekdays[date.weekday - 1];
  }
  
  /// 计算月度总运动时长
  int _calculateMonthlyTotalDuration(Map<String, List<WorkoutRecord>> monthData) {
    int totalDuration = 0;
    for (var dateRecords in monthData.values) {
      for (var record in dateRecords) {
        totalDuration += record.duration;
      }
    }
    return totalDuration;
  }
  
  /// 计算月度总运动次数
  int _calculateMonthlyWorkoutCount(Map<String, List<WorkoutRecord>> monthData) {
    int count = 0;
    for (var dateRecords in monthData.values) {
      count += dateRecords.length;
    }
    return count;
  }
  
  /// 构建月度统计项目
  Widget _buildMonthlyStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.blue,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// 格式化月份显示
  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    return '${parts[0]}年${parts[1]}月';
  }

  @override
  Widget build(BuildContext context) {
    // 将月份键转换为列表并按时间倒序排序
    final monthKeys = _groupedByMonthRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动历史'),
      ),
      body: _groupedByMonthRecords.isEmpty
          ? const Center(child: Text('暂无运动记录', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              itemCount: monthKeys.length,
              itemBuilder: (context, monthIndex) {
                final monthKey = monthKeys[monthIndex];
                final monthData = _groupedByMonthRecords[monthKey]!;
                
                // 将日期键转换为列表并按时间倒序排序
                final dateKeys = monthData.keys.toList()
                  ..sort((a, b) => b.compareTo(a));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 月份标题
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatMonth(monthKey),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 添加月度统计信息
                          Row(
                            children: [
                              _buildMonthlyStatItem(
                                Icons.timer_outlined,
                                '总时长: ${_calculateMonthlyTotalDuration(monthData)}分钟',
                              ),
                              const SizedBox(width: 16),
                              _buildMonthlyStatItem(
                                Icons.repeat,
                                '运动次数: ${_calculateMonthlyWorkoutCount(monthData)}次',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 日期分组
                    ...dateKeys.map((dateKey) {
                      final dateRecords = monthData[dateKey]!;
                      final dateParts = dateKey.split('-');
                      final date = DateTime(
                        int.parse(dateParts[0]),
                        int.parse(dateParts[1]),
                        int.parse(dateParts[2]),
                      );
                      
                      // 计算当天总运动时长
                      final totalDuration = dateRecords.fold<int>(
                        0, (sum, record) => sum + record.duration);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日期标题 - 修改这里，将月份放在前面显示
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${_getWeekdayInChinese(date)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  '总时长: $totalDuration 分钟',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 当天的运动记录列表
                          ...dateRecords.map((workout) {
                            // 获取运动类型信息
                            final exercise = _exercisesMap[workout.exerciseTypeId];
                            final exerciseName = exercise?.name ?? '未知运动';
                            final exerciseIcon = exercise?.icon ?? 'fitness_center';
                            
                            return Slidable(
                              key: Key(workout.id),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.20, // 减小宽度比例，从0.25改为0.20
                                dismissible: null,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _confirmDelete(workout.id),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 22, // 稍微减小图标尺寸
                                            ),
                                            SizedBox(height: 2), // 减小间距
                                            Text(
                                              '删除',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              child: Card(
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
                                  title: Row(
                                    children: [
                                      Text(
                                        exerciseName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${workout.duration}分钟',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${workout.date.hour.toString().padLeft(2, '0')}:${workout.date.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                    
                    // 月份之间的分隔线
                    if (monthIndex < _groupedByMonthRecords.length - 1)
                      Divider(height: 24, thickness: 0.5, indent: 16, endIndent: 16, color: Colors.grey.shade300),
                  ],
                );
              },
            ),
    );
  }
}