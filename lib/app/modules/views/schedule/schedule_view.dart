import 'package:flutter/material.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({Key? key}) : super(key: key);

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
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

    final tasks = [
      {
        'time': '09:00 AM - 10:00 AM',
        'title': 'Kalkulus',
        'desc':
            'Kerjakan latihan soal tentang turunan dan integral. Fokus pada penerapan rumus dan grafi...',
        'priority': 'high',
        'color': const Color(0xFF26BFBF),
      },
      {
        'time': '11:30 AM - 12:30 PM',
        'title': 'Basic Programming',
        'desc':
            'Buat program sederhana menggunakan struktur perulangan dan kondisi (if-else). Simpan hasil da...',
        'priority': 'high',
        'color': const Color(0xFF9B6CEB),
      },
      {
        'time': '11:30 AM - 12:30 PM',
        'title': 'Database',
        'desc':
            'Rancang database mahasiswa dengan minimal 3 tabel (mahasiswa, mata kuliah, nilai). Buat query...',
        'priority': 'medium',
        'color': const Color(0xFF2BD18C),
      },
      {
        'time': '11:30 AM - 12:30 PM',
        'title': 'Mobile Programming',
        'desc':
            'Buat tampilan halaman login dan beranda sederhana menggunakan Flutter. Pastikan desain...',
        'priority': 'low',
        'color': const Color(0xFF3EA7FF),
      },
    ];

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
        toolbarHeight: 90,
        // give title a left inset to match body padding
        titleSpacing: 16,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekdayName,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              dateString,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'Add Task',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    if (idx == days.length) {
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
                          }
                        },
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          // raise the whole circular button a bit so it sits slightly higher
                          child: Align(
                            alignment: const Alignment(0, -0.18),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              // raise the chevron inside the circle slightly more for visual balance
                              child: Align(
                                alignment: const Alignment(0, -0.28),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
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

                    // month short name
                    const monthShort = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    final monthLabel = monthShort[dateObj.month - 1];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = dateObj;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF9BBEFF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0059FF)
                                    : const Color(0xFF9BBEFF),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : const Color(0xFF797979),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  monthLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : const Color(0xFF797979),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(width: 3),
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF26BFBF),
                              ),
                              SizedBox(width: 3),
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF89AFFF),
                              ),
                              SizedBox(width: 3),
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFFFFB017),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    final Color border = t['color'] as Color;
                    final String time = t['time'] as String;
                    final String title = t['title'] as String;
                    final String desc = t['desc'] as String;
                    final String priority = t['priority'] as String;
                    final Color priorityColor = priority == 'high'
                        ? Colors.redAccent
                        : (priority == 'medium' ? Colors.green : Colors.amber);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: border.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // colored accent bar on the left (stretches full height)
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: border.withOpacity(0.95),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.view_in_ar,
                                                    size: 16,
                                                    color: border.withOpacity(
                                                      0.95,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    time,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.more_vert,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      desc,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _PriorityBadge(
                                          color: priorityColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          priority == 'high'
                                              ? 'Prioritas Tinggi'
                                              : (priority == 'medium'
                                                    ? 'Prioritas Sedang'
                                                    : 'Prioritas Rendah'),
                                          style: TextStyle(
                                            color: priorityColor,
                                            fontWeight: FontWeight.w700,
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
                    );
                  },
                ),
              ),
            ],
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
