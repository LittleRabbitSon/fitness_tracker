import 'package:flutter/material.dart';
import 'stats_screen.dart'; // 更改为统计页面
import 'add_workout_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // 页面列表
  final List<Widget> _pages = [
    const StatsScreen(hideFloatingButton: true), // 使用统计页面
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
          // 刷新所有页面数据
          setState(() {
            // 重新创建页面实例以触发刷新
            _pages[0] = const StatsScreen(hideFloatingButton: true);
            _pages[1] = const HistoryScreen();
          });
        }
      });
    } else {
      // 其他按钮切换页面
      setState(() {
        _selectedIndex = index == 0 ? 0 : 1; // 0是统计，2是历史(对应索引1)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 显示当前选中的页面
      bottomNavigationBar: Container(
        height: 85, // 设置底部导航栏高度
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0.5,
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 统计按钮
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.bar_chart, // 更改为统计图表图标
                        color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '统计', // 更改为"统计"
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
                        '历史',
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