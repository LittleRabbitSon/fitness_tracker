/// 运动项目模型类
/// 
/// 用于存储运动项目的基本信息，包括名称、分类和图标
class Exercise {
  /// 运动项目唯一标识符
  final String id;
  
  /// 运动项目名称
  final String name;
  
  /// 运动项目分类（如有氧、力量等）
  final String category;
  
  /// 运动项目图标名称
  final String icon;

  /// 构造函数
  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });

  /// 从Map创建Exercise对象
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      icon: map['icon'],
    );
  }

  /// 将Exercise对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
    };
  }

  /// 创建Exercise的副本并更新指定字段
  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? icon,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
    );
  }

  @override
  String toString() {
    return 'Exercise{id: $id, name: $name, category: $category, icon: $icon}';
  }
}