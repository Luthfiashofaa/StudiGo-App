import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/schedule/schedule_controller.dart';
import '../../controllers/schedule/add_schedule_controller.dart';
import 'add_schedule_view.dart';
import '../../views/shell/app_shell.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({Key? key}) : super(key: key);

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScheduleController _controller;
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
    _controller = Get.put(ScheduleController());
    _controller.fetchSchedules(date: _selectedDate);
    
    // Scroll to today's date after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    final now = DateTime.now();
    
    if (now.year == _selectedDate.year && now.month == _selectedDate.month) {
      // Today is in the current month
      final dayIndex = now.day - 1;
      final cardSize = MediaQuery.of(context).size.width >= 600 ? 70.0 : 64.0;
      final spacing = 10.0;
      final offset = dayIndex * (cardSize + spacing);
      
      _dateScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getDaysInMonth(DateTime date) {
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final firstOfNextMonth = DateTime(
      date.month == 12 ? date.year + 1 : date.year,
      date.month == 12 ? 1 : date.month + 1,
      1,
    );
    return firstOfNextMonth.difference(firstOfMonth).inDays;
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  Widget _buildScheduleCard(Map<String, dynamic> t, bool isTablet) {
    final Color border = _priorityColor(t['priority']?.toString()).withOpacity(0.9);
    final String time = _formatRange(t);
    final String title = t['title']?.toString() ?? '';
    final String desc = t['description']?.toString() ?? '-';
    final String priority = t['priority']?.toString() ?? '';
    final String category = t['category']?.toString() ?? 'Kategori';

    return GestureDetector(
      onTap: () async {
        Get.put(AddScheduleController());
        final result = await Get.to<int>(AddScheduleView(scheduleData: t));
        if (result != null) {
          // handled in shell
        } else {
          await _refreshSchedules();
        }
        Get.delete<AddScheduleController>();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: border.withOpacity(0.3),
            width: isTablet ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: isTablet ? 12 : 10,
              offset: Offset(0, isTablet ? 8 : 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: isTablet ? 8 : 6,
                decoration: BoxDecoration(
                  color: border.withOpacity(0.95),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 16 : 12),
                    bottomLeft: Radius.circular(isTablet ? 16 : 12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 14,
                    vertical: isTablet ? 16 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.view_in_ar,
                                      size: isTablet ? 18 : 16,
                                      color: border.withOpacity(0.95),
                                    ),
                                    SizedBox(width: isTablet ? 10 : 8),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: isTablet ? 15 : 13,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isTablet ? 8 : 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isTablet ? 10 : 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: isTablet ? 26 : 24,
                                ),
                                onPressed: () => _confirmDelete(t['id'].toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 10 : 8),
                      Text(
                        desc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                      SizedBox(height: isTablet ? 14 : 12),
                      Row(
                        children: [
                          Icon(
                            Icons.import_contacts,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _PriorityBadge(
                            color: _priorityColor(priority),
                            size: isTablet ? 22 : 18,
                          ),
                          SizedBox(width: isTablet ? 10 : 8),
                          Text(
                            priority.isEmpty ? 'Prioritas' : 'Prioritas $priority',
                            style: TextStyle(
                              color: _priorityColor(priority),
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 15 : 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshSchedules() async {
    await _controller.fetchSchedules(date: _selectedDate);
  }

  String _formatRange(Map<String, dynamic> item) {
    final start = DateTime.tryParse(item['start_time']?.toString() ?? '')?.toLocal();
    final end = DateTime.tryParse(item['end_time']?.toString() ?? '')?.toLocal();
    if (start == null || end == null) return '';
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} - ${fmt(end)}';
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'Tinggi':
        return Colors.redAccent;
      case 'Sedang':
        return Colors.amber;
      case 'Rendah':
        return Colors.green;
      default:
        return const Color(0xFF2B7FFF);
    }
  }

  Color? _priorityDotColor(String? p) {
    switch (p) {
      case 'Tinggi':
        return Colors.redAccent;
      case 'Sedang':
        return Colors.amber;
      case 'Rendah':
        return Colors.green;
      default:
        return null;
    }
  }

  List<Color> _colorsForDate(DateTime date) {
    final set = <Color>{};
    for (final item in _controller.allSchedules) {
      final bool repeats = item['repeat_daily'] == true;
      final rawDate = item['date']?.toString();
      final rawStart = item['start_time']?.toString();

      DateTime? dateValue;
      if (rawDate != null) {
        try {
          dateValue = DateTime.parse(rawDate.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          dateValue = DateTime.tryParse(rawDate)?.toLocal();
        }
      }
      if (dateValue == null && rawStart != null) {
        try {
          dateValue = DateTime.parse(rawStart.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          dateValue = DateTime.tryParse(rawStart)?.toLocal();
        }
      }
      if (dateValue == null) continue;

      final itemDate = DateTime(dateValue.year, dateValue.month, dateValue.day);
      final bool matches = repeats
          ? !date.isBefore(itemDate)
          : (itemDate.year == date.year &&
              itemDate.month == date.month &&
              itemDate.day == date.day);

      if (matches) {
        final c = _priorityDotColor(item['priority']?.toString());
        if (c != null) set.add(c);
      }
    }
    return set.toList();
  }

  Future<void> _confirmDelete(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _controller.deleteSchedule(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;
        return _buildContent(context, isTablet);
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    // show a full month (all days of the selected month) in the top horizontal list
    final firstOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    // compute number of days in the selected month
    final firstOfNextMonth = DateTime(
      _selectedDate.month == 12 ? _selectedDate.year + 1 : _selectedDate.year,
      _selectedDate.month == 12 ? 1 : _selectedDate.month + 1,
      1,
    );
    final daysInMonth = firstOfNextMonth.difference(firstOfMonth).inDays;

    final days = List.generate(daysInMonth, (i) {
      final now = DateTime(_selectedDate.year, _selectedDate.month, i + 1);
      return {
        'label': [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][(now.weekday - 1) % 7],
        'day': now.day.toString().padLeft(2, '0'),
        'date': now,
      };
    });

    final now = DateTime.now();
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateString =
        '${monthNames[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekdayName = weekdayNames[now.weekday - 1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // slightly reduce toolbar height so calendar content moves up
        toolbarHeight: isTablet ? 110 : 90,
        // give title a left inset to match body padding
        titleSpacing: isTablet ? 24 : 16,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekdayName,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              dateString,
              style: TextStyle(
                color: Colors.black87,
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isTablet ? 20.0 : 12.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Register controller before opening view
                Get.put(AddScheduleController());
                final result = await Get.to<int>(const AddScheduleView());
                // If user navigated away via navbar in AddScheduleView,
                // avoid popping the root to prevent a black screen.
                if (result != null) {
                  // Tab change will be handled by ShellController inside AddScheduleView.
                  // Nothing to do here.
                } else {
                  // User just saved/closed normally, refresh schedules
                  await _refreshSchedules();
                }
                // Clean up controller after closing view
                Get.delete<AddScheduleController>();
              },
              icon: Icon(
                Icons.add,
                size: isTablet ? 20 : 18,
                color: Colors.white,
              ),
              label: Text(
                'Add Task',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 12 : 10,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 1000 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24.0 : 16.0,
                isTablet ? 16.0 : 12.0,
                isTablet ? 24.0 : 16.0,
                isTablet ? 16.0 : 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: isTablet ? 100 : 86,
                    child: ListView.separated(
                      controller: _dateScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length + 1,
                      separatorBuilder: (_, __) => SizedBox(
                        width: isTablet ? 10 : 10,
                      ),
                      itemBuilder: (context, idx) {
                        if (idx == days.length) {
                          final buttonSize = isTablet ? 70.0 : 64.0;
                          final iconSize = isTablet ? 48.0 : 44.0;
                          return GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                                await _refreshSchedules();
                              }
                            },
                            child: SizedBox(
                              width: buttonSize,
                              height: buttonSize,
                              // raise the whole circular button a bit so it sits slightly higher
                              child: Align(
                                alignment: const Alignment(0, -0.18),
                                child: Container(
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  // raise the chevron inside the circle slightly more for visual balance
                                  child: Align(
                                    alignment: const Alignment(0, -0.28),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: const Color.fromARGB(
                                        255,
                                        158,
                                        158,
                                        158,
                                      ),
                                      size: isTablet ? 24 : 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final d = days[idx] as Map<String, dynamic>;
                        final day = d['day'] as String;
                        final dateObj = d['date'] as DateTime;
                        final isSelected =
                            dateObj.year == _selectedDate.year &&
                            dateObj.month == _selectedDate.month &&
                            dateObj.day == _selectedDate.day;

                        final cardSize = isTablet ? 72.0 : 64.0;
                        final selectedColor = isTablet
                          ? const Color(0xFF7FB3FF)
                          : const Color(0xFF9BBEFF);
                        final selectedBorder = isTablet
                          ? const Color(0xFF4C8DFF)
                          : const Color(0xFF0059FF);
                        final unselectedColor =
                          isTablet ? const Color(0xFFF5F7FB) : Colors.white;
                        final unselectedBorder = isTablet
                          ? const Color(0xFFB7CCFF)
                          : const Color(0xFF9BBEFF);

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              _selectedDate = dateObj;
                            });
                            await _refreshSchedules();
                          },
                          child: Column(
                            children: [
                              Container(
                                width: cardSize,
                                height: cardSize,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? selectedColor
                                      : unselectedColor,
                                  borderRadius: BorderRadius.circular(
                                    isTablet ? 14 : 12,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? selectedBorder
                                        : unselectedBorder,
                                    width: isTablet ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      d['label'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : const Color(0xFF797979),
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 6 : 4),
                                    Text(
                                      day,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : const Color(0xFF797979),
                                        fontWeight: FontWeight.w800,
                                        fontSize: isTablet ? 22 : 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Obx(() {
                                final colors = _colorsForDate(dateObj);
                                if (colors.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: isTablet ? 4 : 3),
                                    ...List.generate(colors.length, (i) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: isTablet ? 4 : 3,
                                            backgroundColor: colors[i],
                                          ),
                                          if (i < colors.length - 1)
                                            SizedBox(width: isTablet ? 4 : 3),
                                        ],
                                      );
                                    }),
                                    SizedBox(width: isTablet ? 4 : 3),
                                  ],
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isTablet ? 18 : 12),
                  Expanded(
                    child: Obx(() {
                      if (_controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (_controller.schedules.isEmpty) {
                        return Center(
                          child: Text(
                            'Belum ada jadwal untuk tanggal ini.',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        );
                      }

                      if (isTablet) {
                        return RefreshIndicator(
                          onRefresh: _refreshSchedules,
                          child: GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 1.85,
                            ),
                            itemCount: _controller.schedules.length,
                            itemBuilder: (context, index) {
                              final t = _controller.schedules[index];
                              return _buildScheduleCard(t, isTablet);
                            },
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshSchedules,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _controller.schedules.length,
                          separatorBuilder: (_, __) => SizedBox(
                            height: isTablet ? 22 : 18,
                          ),
                          itemBuilder: (context, index) {
                            final t = _controller.schedules[index];
                            return _buildScheduleCard(t, isTablet);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final Color color;
  final double size;
  const _PriorityBadge({Key? key, required this.color, this.size = 18})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double outer = size;
    final double innerWhite = size * 0.62;
    final double center = size * 0.48;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // outer ring
          Container(
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: outer * 0.12),
            ),
          ),
          // white inner circle
          Container(
            width: innerWhite,
            height: innerWhite,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          // center dot
          Container(
            width: center,
            height: center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

// Lightweight entry to rebuild AppShell with a specific tab index passed via RouteSettings.arguments.
class _AppShellEntry extends StatelessWidget {
  const _AppShellEntry({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int initialIndex = 0;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['tabIndex'] is int) {
      initialIndex = args['tabIndex'] as int;
    }
    // Import deferred to avoid circular import at top; use runtime import via builder in route.
    return AppShell(initialIndex: initialIndex);
  }
}
