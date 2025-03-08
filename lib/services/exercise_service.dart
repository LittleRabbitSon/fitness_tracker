import '../models/exercise.dart';
import '../services/database_service.dart';

/// 运动项目服务类
/// 
/// 提供与运动项目相关的业务逻辑操作，封装对数据库的访问
class ExerciseService {
  final DatabaseService _databaseService = DatabaseService();
  
  /// 获取所有运动项目
  Future<List<Exercise>> getAllExercises() async {
    try {
      return await _databaseService.getAllExercises();
    } catch (e) {
      print('获取所有运动项目失败: $e');
      rethrow;
    }
  }
  
  /// 根据ID获取运动项目
  Future<Exercise?> getExerciseById(String id) async {
    try {
      return await _databaseService.getExerciseById(id);
    } catch (e) {
      print('根据ID获取运动项目失败: $e');
      rethrow;
    }
  }
}