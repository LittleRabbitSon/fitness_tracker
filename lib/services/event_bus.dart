import 'dart:async';

/// 事件总线类
/// 
/// 提供应用内不同组件之间的通信机制，基于发布-订阅模式
class EventBus {
  /// 事件流控制器
  final StreamController _streamController;
  
  /// 获取事件流
  Stream get stream => _streamController.stream;

  /// 构造函数
  /// 
  /// [sync] - 是否使用同步流控制器
  EventBus({bool sync = false})
      : _streamController = StreamController.broadcast(sync: sync);

  /// 发布事件
  /// 
  /// [event] - 要发布的事件对象
  void fire(event) {
    _streamController.add(event);
  }

  /// 监听特定类型的事件
  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  /// 关闭事件总线
  /// 
  /// 释放资源，防止内存泄漏
  void dispose() {
    _streamController.close();
  }
}

/// 数据更新事件类
/// 
/// 用于通知应用中的其他组件数据已更新
class DataUpdatedEvent {
  /// 更新的数据类型
  final String dataType; // 将 type 改为 dataType
  
  /// 构造函数
  /// 
  /// [dataType] - 更新的数据类型，如 'workout'
  DataUpdatedEvent(this.dataType); // 将参数名也改为 dataType
}

/// 全局事件总线实例
final eventBus = EventBus();