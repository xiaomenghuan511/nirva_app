//import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirva_app/event_card.dart';
import 'package:nirva_app/providers/journal_files_provider.dart';
import 'package:nirva_app/providers/favorites_provider.dart';
import 'package:nirva_app/quote_carousel.dart';
import 'package:nirva_app/week_calendar_widget.dart';
import 'package:nirva_app/month_calendar_page.dart';
import 'package:nirva_app/data.dart';

class SmartDiaryPage extends StatefulWidget {
  const SmartDiaryPage({super.key});

  @override
  State<SmartDiaryPage> createState() => _SmartDiaryPageState();
}

class _SmartDiaryPageState extends State<SmartDiaryPage> {
  DateTime _focusedDay = DateTime.now(); // 给一个默认值
  DateTime? _selectedDay;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // 在postFrameCallback中同步Provider的初始状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final journalFilesProvider = Provider.of<JournalFilesProvider>(
          context,
          listen: false,
        );
        setState(() {
          _focusedDay = journalFilesProvider.selectedDateTime;
          _selectedDay = journalFilesProvider.selectedDateTime;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalFilesProvider>(
      builder: (context, journalProvider, child) {
        // 示例：标记特定日期为红色
        Set<DateTime> journalDates = {};
        var allJournalFiles = journalProvider.journalFiles;
        for (var file in allJournalFiles) {
          DateTime date = DateTime.parse(file.time_stamp);
          journalDates.add(date);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部引言卡片轮播
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: QuoteCarousel(),
              ),

              // 添加日期标题栏组件
              _buildDateHeader(),

              // 周日历组件替代原来的日期标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: WeekCalendarWidget(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  onDaySelected: _updateSelectedDay,
                  redMarkedDays: journalDates, // 传入需要标红的日期
                ),
              ),

              // 动态展示日记条目
              _buildEventList(journalProvider.currentJournalFile.events),
            ],
          ),
        );
      },
    );
  }

  void _updateSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;

      // 这里需要修改！！
      final journalFilesProvider = Provider.of<JournalFilesProvider>(
        context,
        listen: false,
      );
      journalFilesProvider.selectDateTime(selectedDay);
    });
  }

  // 提取的日期标题栏组件函数
  Widget _buildDateHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 56.0,
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F7),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 日历图标（左侧）
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.purple,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MonthCalendarPage(
                        initialFocusedDay: _focusedDay,
                        initialSelectedDay: _selectedDay,
                        onDaySelected: _updateSelectedDay,
                      ),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
          ),

          // 右侧图标组
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isFavorite
                      ? Icons
                          .star // 实心图标
                      : Icons.star_border_outlined, // 空心图标
                  color: _isFavorite ? Colors.yellow : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite; // 切换收藏状态
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36.0,
                  minHeight: 36.0,
                ),
              ),
              // const SizedBox(width: 16),
              // IconButton(
              //   icon: const Icon(Icons.search),
              //   onPressed: () => debugPrint('点击了搜索图标'),
              //   color: Colors.grey,
              //   padding: EdgeInsets.zero,
              //   constraints: const BoxConstraints(
              //     minWidth: 36.0,
              //     minHeight: 36.0,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<EventAnalysis> events) {
    List<EventAnalysis> finalEvents = [];
    if (_isFavorite) {
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      for (var entry in events) {
        if (favoritesProvider.checkFavorite(entry)) {
          finalEvents.add(entry);
        }
      }
    } else {
      // 如果不是收藏状态，获取所有日记条目
      finalEvents = events;
    }

    return ListView.builder(
      key: UniqueKey(), // 强制刷新 ListView.builder
      shrinkWrap: true, // 使 ListView 适应父组件高度
      physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
      itemCount: finalEvents.length,
      itemBuilder: (context, index) {
        return EventCard(
          //diaryData: finalDiaryEntries[index],
          eventData: finalEvents[index],
        );
      },
    );
  }
}
