import 'package:flutter/material.dart';
// import 'screens/monthly_screen.dart'; // 替换为月度统计页面
import 'screens/history_screen.dart';
import 'screens/add_workout_screen.dart';
import 'screens/stats_screen.dart'; // 添加统计页面导入
import 'package:flutter_localizations/flutter_localizations.dart'; // 添加本地化支持
import 'package:intl/date_symbol_data_local.dart'; // 添加日期格式化本地化支持
import 'services/event_bus.dart'; // 添加事件总线导入

/// 应用程序入口点
void main() async {
  // 初始化 Flutter 绑定，确保Flutter引擎与宿主平台通信正常
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化中文日期格式化的语言环境数据
  await initializeDateFormatting('zh_CN', null);
  
  // 运行应用程序
  runApp(const MyApp());
}

/// 应用程序根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健身追踪',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // 启用 Material 3 设计
        scaffoldBackgroundColor: Colors.white, // 设置应用整体背景色为白色
        cardTheme: const CardTheme(
          color: Colors.white, // 设置卡片背景色为白色
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // 设置应用栏背景色为白色
          elevation: 0, // 移除阴影
          centerTitle: true, // 标题居中
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: Colors.black87), // 应用栏图标颜色
        ),
      ),
      home: const MainScreen(), // 设置主屏幕
      debugShowCheckedModeBanner: false, // 移除调试标签
      // 添加本地化支持
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'), // 设置默认语言为中文
    );
  }
}

/// 主屏幕组件，包含底部导航栏和页面切换逻辑
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// 主屏幕状态管理
class _MainScreenState extends State<MainScreen> {
  // 当前选中的底部导航栏索引
  int _selectedIndex = 0;
  
  // 应用程序的主要页面列表
  final List<Widget> _pages = [
    const StatsScreen(hideFloatingButton: true), // 使用统计页面替代月度页面
    const HistoryScreen(),
  ];

  /// 底部导航栏项目点击处理
  void _onItemTapped(int index) {
    if (index == 1) {
      // 中间按钮点击时打开添加页面
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
      ).then((result) {
        // 如果返回结果为true，表示添加了新记录，需要刷新数据
        if (result == true) {
          // 通过事件总线发送数据更新事件
          eventBus.fire(DataUpdatedEvent('workout'));
        }
      });
    } else {
      // 其他按钮切换页面
      setState(() {
        _selectedIndex = index == 0 ? 0 : 1; // 0是本月，2是历史(对应索引1)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 显示当前选中的页面
      bottomNavigationBar: Container(
        height: 80, // 设置底部导航栏高度
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 158, 158, 158),
              spreadRadius: 0,
              blurRadius: 2,
              offset: Offset(0, -1), // 只在顶部添加轻微阴影
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 本月按钮
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_month, // 更改为日历月视图图标
                        color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '统计', // 更改为"本月"
                        style: TextStyle(
                          color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 添加按钮
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 历史按钮
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(2),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.history,
                        color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '历史', // 更改为"统计"
                        style: TextStyle(
                          color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}