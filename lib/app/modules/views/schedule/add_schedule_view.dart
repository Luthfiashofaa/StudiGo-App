import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/schedule/add_schedule_controller.dart';

class AddScheduleView extends StatefulWidget {
  const AddScheduleView({Key? key}) : super(key: key);

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  late final AddScheduleController _controller;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _repeatDaily = false;
  String? _selectedCategory;
  String _priority = 'Tinggi';
  String? _editingId;

  List<String> categories = ['Belajar', 'Istirahat', 'Hiburan', 'Tugas'];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AddScheduleController>();
    final args = Get.arguments;
    if (args is Map && args['schedule'] != null) {
      final sched = args['schedule'] as Map;
      _editingId = sched['id']?.toString();
      _nameCtrl.text = sched['title']?.toString() ?? '';
      _descCtrl.text = sched['description']?.toString() ?? '';
      _repeatDaily = sched['repeat_daily'] == true;
      _selectedCategory = sched['category']?.toString();
      _priority = sched['priority']?.toString() ?? _priority;

      final startRaw = sched['start_time']?.toString();
      final endRaw = sched['end_time']?.toString();
      final start = startRaw != null ? DateTime.tryParse(startRaw) : null;
      final end = endRaw != null ? DateTime.tryParse(endRaw) : null;
      if (start != null) {
        _selectedDate = DateTime(start.year, start.month, start.day);
        _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
      }
      if (end != null) {
        _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? now,
    );
    return picked;
  }

  String _formatTimeRange() {
    if (_startTime == null || _endTime == null) return '00 : 00 - 00 : 00';
    String fmt(TimeOfDay t) =>
        t.hour.toString().padLeft(2, '0') +
        ' : ' +
        t.minute.toString().padLeft(2, '0');
    return '${fmt(_startTime!)} - ${fmt(_endTime!)}';
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    final title = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (title.isEmpty) {
      Get.snackbar('Validasi', 'Nama jadwal wajib diisi');
      return;
    }
    if (_selectedDate == null) {
      Get.snackbar('Validasi', 'Tanggal wajib dipilih');
      return;
    }
    if (_startTime == null || _endTime == null) {
      Get.snackbar('Validasi', 'Waktu mulai & selesai wajib dipilih');
      return;
    }

    try {
      if (_editingId != null) {
        await _controller.updateSchedule(
          id: _editingId!,
          title: title,
          description: description,
          date: _selectedDate!,
          startTime: _startTime!,
          endTime: _endTime!,
          repeatDaily: _repeatDaily,
          priority: _priority,
          category: _selectedCategory,
        );
      } else {
        await _controller.createSchedule(
          title: title,
          description: description,
          date: _selectedDate!,
          startTime: _startTime!,
          endTime: _endTime!,
          repeatDaily: _repeatDaily,
          priority: _priority,
          category: _selectedCategory,
        );
      }

      if (!mounted) return;
      Get.snackbar(
        'Berhasil',
        _editingId != null
            ? 'Jadwal berhasil diperbarui'
            : 'Jadwal berhasil disimpan',
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _editingId != null ? 'Edit Task' : 'Tambah Task',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Jadwal',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _card(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh : Sesi Belajar Fisika',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 8,
                    ),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Tanggal',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: _card(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Date'
                                    : '${_selectedDate!.day.toString().padLeft(2, '0')} ${_selectedDate!.month}/${_selectedDate!.year}',
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        final pickedStart = await _pickTime(_startTime);
                        if (pickedStart == null) return;
                        final pickedEnd = await _pickTime(
                          _endTime ?? pickedStart,
                        );
                        setState(() {
                          _startTime = pickedStart;
                          if (pickedEnd != null) _endTime = pickedEnd;
                        });
                      },
                      child: _card(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatTimeRange(),
                                style: TextStyle(color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _card(
                child: TextField(
                  controller: _descCtrl,
                  minLines: 5,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Contoh : Kerjakan latihan soal tentang turunan dan integral. Fokus pada penerapan rumus dan grafik fungsi.',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _repeatDaily = !_repeatDaily),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7DF6), // blue box background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            'Ulangi Setiap Hari',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _repeatDaily,
                        // when ON, thumb and track use green
                        activeThumbColor: Colors.white,
                        activeTrackColor: Color(0xFFB8E6FE),
                        // when OFF, use light thumb/track for contrast on blue box
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Color(0xFFD9D9D9),
                        onChanged: (v) => setState(() => _repeatDaily = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _card(
                child: Row(
                  children: [
                    // left small box containing the field title 'Kategori'
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),

                      child: Text(
                        'Kategori',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // push dropdown to the right
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : null,
                            hint: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Pilih',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                            isExpanded: false,
                            // hide the default right-side caret; icon will be shown inside the pill
                            icon: const SizedBox.shrink(),
                            selectedItemBuilder: (context) {
                              return categories.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        c,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                            items: categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Prioritas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _card(
                child: Wrap(
                  spacing: 43,
                  runSpacing: 8,
                  children: [
                    _priorityChip('Tinggi'),
                    _priorityChip('Sedang'),
                    _priorityChip('Rendah'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 54,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: _controller.isSaving.value
                          ? null
                          : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7DF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _controller.isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _editingId != null
                                  ? 'Perbarui Target'
                                  : 'Simpan Target',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _priorityChip(String label) {
    final bool selected = _priority == label;

    // map label to color when selected
    Color selectedColor;
    Color selectedTextColor = Colors.white;
    switch (label) {
      case 'Tinggi':
        selectedColor = Colors.red;
        break;
      case 'Sedang':
        selectedColor = Colors.amber; // yellow-ish
        // use dark text on yellow for readability
        selectedTextColor = Colors.black87;
        break;
      case 'Rendah':
        selectedColor = Colors.green;
        break;
      default:
        selectedColor = const Color(0xFF2D7DF6);
    }

    return GestureDetector(
      onTap: () => setState(() => _priority = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selectedTextColor : Colors.grey.shade800,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _bottomNavBar() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF2D7DF6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.home, color: Colors.white),
          ),
          // calendar icon highlighted
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: Color(0xFF2D7DF6)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.track_changes, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
