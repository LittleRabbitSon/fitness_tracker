/// 运动记录模型类
/// 
/// 用于存储用户的运动记录信息，包括运动类型、日期、时长和备注
class WorkoutRecord {
  /// 记录唯一标识符
  final String id;
  
  /// 运动类型ID，关联到Exercise表
  final String exerciseTypeId;
  
  /// 运动日期和时间
  final DateTime date;
  
  /// 运动时长（分钟）
  final int duration;
  
  /// 备注信息（可选）
  final String? notes;

  /// 构造函数
  WorkoutRecord({
    required this.id,
    required this.exerciseTypeId,
    required this.date,
    required this.duration,
    this.notes,
  });

  /// 从Map创建WorkoutRecord对象
  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutRecord(
      id: map['id'],
      exerciseTypeId: map['exerciseTypeId'],
      date: DateTime.parse(map['date']),
      duration: map['duration'],
      notes: map['notes'],
    );
  }

  /// 将WorkoutRecord对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseTypeId': exerciseTypeId,
      'date': date.toIso8601String(),
      'duration': duration,
      'notes': notes,
    };
  }

  /// 创建WorkoutRecord的副本并更新指定字段
  WorkoutRecord copyWith({
    String? id,
    String? exerciseTypeId,
    DateTime? date,
    int? duration,
    String? notes,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'WorkoutRecord{id: $id, exerciseTypeId: $exerciseTypeId, date: $date, duration: $duration, notes: $notes}';
  }
}