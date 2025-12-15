import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/schedule/add_schedule_controller.dart';
import '../../controllers/shell/shell_controller.dart';

class AddScheduleView extends StatefulWidget {
  final Map<String, dynamic>? scheduleData;
  const AddScheduleView({Key? key, this.scheduleData}) : super(key: key);

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
  bool _isSaving = false;
  bool _nameError = false;
  bool _descError = false;
  bool _dateError = false;
  bool _timeError = false;
  bool _categoryError = false;

  List<String> categories = ['Belajar', 'Istirahat', 'Hiburan', 'Tugas'];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AddScheduleController>();

    // Try to get schedule data from widget parameter first, then from Get.arguments
    final sched =
        widget.scheduleData ??
        (Get.arguments is Map ? Get.arguments['schedule'] : null);

    if (sched is Map && sched.isNotEmpty) {
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

  Widget _card({required Widget child, bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.grey.shade200,
        ),
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

    setState(() {
      _nameError = title.isEmpty;
      _descError = description.isEmpty;
      _dateError = _selectedDate == null;
      _timeError = _startTime == null || _endTime == null;
      _categoryError = _selectedCategory == null || _selectedCategory!.isEmpty;
    });

    if (_nameError || _descError || _dateError || _timeError || _categoryError) {
      final missing = <String>[];
      if (_nameError) missing.add('Nama jadwal');
      if (_descError) missing.add('Deskripsi');
      if (_dateError) missing.add('Tanggal');
      if (_timeError) missing.add('Waktu mulai & selesai');
      if (_categoryError) missing.add('Kategori');
      Get.snackbar('Validasi', 'Lengkapi field: ${missing.join(', ')}');
      return;
    }

    // Pastikan waktu selesai setelah waktu mulai untuk mencegah jadwal tidak valid.
    final startTotalMinutes = (_startTime!.hour * 60) + _startTime!.minute;
    final endTotalMinutes = (_endTime!.hour * 60) + _endTime!.minute;
    if (endTotalMinutes <= startTotalMinutes) {
      setState(() => _timeError = true);
      Get.snackbar('Validasi', 'Waktu selesai harus setelah waktu mulai');
      return;
    }

    setState(() {
      _nameError = false;
      _descError = false;
      _dateError = false;
      _timeError = false;
      _categoryError = false;
    });

    setState(() => _isSaving = true);
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
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
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 20,
                isTablet ? 24 : 18,
                isTablet ? 32 : 20,
                isTablet ? 28 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildContent(isTablet),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildContent(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Jadwal',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _card(
          isError: _nameError,
          child: TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Contoh : Sesi Belajar Fisika',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: isTablet ? 10 : 5,
                horizontal: isTablet ? 12 : 8,
              ),
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 22 : 16),
        Text(
          'Tanggal',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _pickDate,
                child: _card(
                  isError: _dateError,
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
                            fontSize: isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Icon(
                        Icons.schedule,
                        color: Colors.grey,
                        size: isTablet ? 22 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final pickedStart = await _pickTime(_startTime);
                  if (pickedStart == null) return;
                  final pickedEnd = await _pickTime(_endTime ?? pickedStart);
                  setState(() {
                    _startTime = pickedStart;
                    if (pickedEnd != null) _endTime = pickedEnd;
                  });
                },
                child: _card(
                  isError: _timeError,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTimeRange(),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: isTablet ? 22 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 22 : 16),
        Text(
          'Deskripsi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _card(
          isError: _descError,
          child: TextField(
            controller: _descCtrl,
            minLines: isTablet ? 6 : 5,
            maxLines: isTablet ? 6 : 5,
            decoration: InputDecoration(
              hintText:
                  'Contoh : Kerjakan latihan soal tentang turunan dan integral. Fokus pada penerapan rumus dan grafik fungsi.',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 22 : 16),
        GestureDetector(
          onTap: () => setState(() => _repeatDaily = !_repeatDaily),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 12 : 8,
              horizontal: isTablet ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7DF6),
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
                  activeThumbColor: Colors.white,
                  activeTrackColor: Color(0xFFB8E6FE),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Color(0xFFD9D9D9),
                  onChanged: (v) => setState(() => _repeatDaily = v),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isTablet ? 28 : 20),
        _card(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 12 : 8,
                  horizontal: isTablet ? 16 : 12,
                ),
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 22 : 20,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categories.contains(_selectedCategory)
                          ? _selectedCategory
                          : null,
                      hint: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 8 : 6,
                          horizontal: isTablet ? 18 : 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _categoryError
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                          ),
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
                                color: _categoryError
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
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
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _categoryError = false;
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 22 : 16),
        Text(
          'Prioritas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _card(
          child: Wrap(
            spacing: isTablet ? 24 : 16,
            runSpacing: isTablet ? 12 : 8,
            children: [
              _priorityChip('Tinggi', isTablet),
              _priorityChip('Sedang', isTablet),
              _priorityChip('Rendah', isTablet),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 30 : 24),
        Center(
          child: SizedBox(
            width: isTablet ? 320 : 250,
            height: isTablet ? 58 : 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                ),
              ),
              child: _isSaving
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
                      _editingId != null ? 'Perbarui Target' : 'Simpan Target',
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    const primaryBlue = Color(0xFF1557D4);
    const activeBoxColor = Color(0xFF6097FF);

    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(
                icon: Icons.home,
                isActive: false,
                onTap: () => _handleNavTap(0),
              ),
              _buildNavIcon(
                icon: Icons.event,
                isActive: true,
                onTap: () => _handleNavTap(1),
              ),
              _buildNavIcon(
                icon: Icons.track_changes,
                isActive: false,
                onTap: () => _handleNavTap(2),
              ),
              _buildNavIcon(
                icon: Icons.person,
                isActive: false,
                onTap: () => _handleNavTap(3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const activeBoxColor = Color(0xFF6097FF);
    return Container(
      width: 50,
      height: 50,
      decoration: isActive
          ? BoxDecoration(
              color: activeBoxColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      alignment: Alignment.center,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 56, height: 56),
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    // Jika klik icon calendar (schedule), tetap di halaman ini (jangan pop)
    if (index == 1) {
      return;
    }
    // Update shell tab index centrally for smooth tab switch, then close this view.
    final shell = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : Get.put(ShellController());
    shell.setIndex(index);
    Get.back();
  }

  Widget _priorityChip(String label, [bool isTablet = false]) {
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
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 10 : 8,
          horizontal: isTablet ? 20 : 18,
        ),
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
}
