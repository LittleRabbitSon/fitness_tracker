import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 添加CupertinoDatePicker支持
import '../models/workout_record.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../services/exercise_service.dart';
import '../services/event_bus.dart'; // 添加导入
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:intl/intl.dart'; // 添加日期格式化支持

/// 添加运动记录页面
/// 
/// 允许用户创建新的运动记录，包括选择运动类型、日期时间、时长和备注
class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

/// 添加运动记录页面状态管理
class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _exerciseService = ExerciseService();
  
  // 表单数据
  int _duration = 0;
  String _selectedExerciseId = '1';
  String _selectedExerciseName = '';
  String _selectedExerciseIcon = 'fitness_center'; // 添加这一行
  List<Exercise> _exercises = [];
  DateTime _selectedDate = DateTime.now();
  String? _notes;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  /// 加载所有运动项目数据
  /// 加载运动项目列表
  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.getAllExercises();
      setState(() {
        _exercises = exercises;
        if (_exercises.isNotEmpty) {
          final defaultExercise = _exercises.first;
          _selectedExerciseId = defaultExercise.id;
          _selectedExerciseName = defaultExercise.name;
          _selectedExerciseIcon = defaultExercise.icon; // 添加这一行
        }
      });
    } catch (e) {
      print('加载运动项目失败: $e');
    }
  }

  /// 显示运动项目选择器底部弹窗
  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '选择运动项目',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(
                          _getIconData(exercise.icon),
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(exercise.name),
                      subtitle: Text(exercise.category),
                      onTap: () {
                        setState(() {
                          _selectedExerciseId = exercise.id;
                          _selectedExerciseName = exercise.name;
                          _selectedExerciseIcon = exercise.icon; // 添加这一行
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示日期时间选择器底部弹窗
  void _showDatePicker() {
    // 保存当前选择的日期，以便在取消时恢复
    // final initialDate = _selectedDate;
    DateTime tempPickDate = _selectedDate;
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              // 顶部操作栏
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('取消'),
                    ),
                    const Text('选择日期和时间', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempPickDate;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              // 日期选择器主体
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: _selectedDate,
                    onDateTimeChanged: (DateTime newDate) {
                      tempPickDate = newDate;
                    },
                    use24hFormat: true, // 使用24小时制
                    dateOrder: DatePickerDateOrder.ymd, // 年-月-日顺序
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 保存运动记录到数据库
  void _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 创建运动记录对象
        final workout = WorkoutRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate,
          duration: _duration,
          exerciseTypeId: _selectedExerciseId,
          notes: _notes,
        );

        print('保存记录: ${workout.toMap()}'); // 添加调试日志
        
        // 保存到数据库
        await _databaseService.addWorkoutRecord(workout);
        
        // 发送数据更新事件，通知其他页面刷新
        eventBus.fire(DataUpdatedEvent('workout'));
        
        // 返回上一页，并传递成功标志
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('保存运动记录失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加运动记录'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 运动项目选择
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: _showExercisePicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  _getIconData(_selectedExerciseIcon),
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedExerciseName.isEmpty ? '选择运动项目' : _selectedExerciseName,
                                style: TextStyle(
                                  color: _selectedExerciseName.isEmpty ? Colors.grey : Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 日期和时间选择
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: _showDatePicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.year}年${_selectedDate.month.toString().padLeft(2, '0')}月${_selectedDate.day.toString().padLeft(2, '0')}日 ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 运动时长
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: '运动时长（分钟）',
                        border: InputBorder.none,
                        icon: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.timer,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _duration = int.tryParse(value) ?? 0;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入运动时长';
                        }
                        if (int.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                // 备注
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: '备注（可选）',
                        hintText: '添加运动备注...',
                        border: InputBorder.none,
                        icon: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.note_alt_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        _notes = value.isEmpty ? null : value;
                      },
                    ),
                  ),
                ),
                
                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存记录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 添加图标获取方法
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
}