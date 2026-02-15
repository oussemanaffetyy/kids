import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_v1/services/student_store.dart';
import 'package:project_v1/services/stats_store.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math' as math;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  List<Student> _students = [];
  List<StatRecord> _stats = [];
  bool _loading = true;
  bool _byMonth = false;
  DateTime _selectedDate = DateTime.now();
  _SortKey _sortKey = _SortKey.date;
  bool _sortAsc = false;
  int? _lineHoverIndex;
  Offset? _lineHoverOffset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StudentStore.instance.loadStudents();
    final stats = await StatsStore.instance.loadStats();
    if (!mounted) return;
    setState(() {
      _students = list;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _addStudent() async {
    final name = _nameController.text.trim();
    final birth = _birthController.text.trim();
    if (name.isEmpty || birth.isEmpty) return;
    final updated = [
      Student(name: name, birthDate: birth),
    ];
    await StudentStore.instance.saveStudents(updated);
    if (!mounted) return;
    setState(() {
      _students = updated;
      _nameController.clear();
      _birthController.clear();
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 4, now.month, now.day),
      firstDate: DateTime(2010),
      lastDate: now,
      helpText: 'تاريخ الميلاد',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    _birthController.text = '$yyyy-$mm-$dd';
  }

  Future<void> _removeStudent(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف هذا التلميذ؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    final updated = [..._students]..removeAt(index);
    await StudentStore.instance.saveStudents(updated);
    await StatsStore.instance.clearStats();
    if (!mounted) return;
    setState(() {
      _students = updated;
      _stats = [];
    });
  }

  Future<void> _editStudent(int index) async {
    final current = _students[index];
    final nameController = TextEditingController(text: current.name);
    final birthController = TextEditingController(text: current.birthDate);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل بيانات التلميذ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: birthController,
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 4, now.month, now.day),
                      firstDate: DateTime(2010),
                      lastDate: now,
                      helpText: 'تاريخ الميلاد',
                      builder: (context, child) {
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                    );
                    if (picked == null) return;
                    final yyyy = picked.year.toString().padLeft(4, '0');
                    final mm = picked.month.toString().padLeft(2, '0');
                    final dd = picked.day.toString().padLeft(2, '0');
                    birthController.text = '$yyyy-$mm-$dd';
                  },
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الميلاد',
                    suffixIcon: Icon(Icons.date_range),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    final birth = birthController.text.trim();
    if (name.isEmpty || birth.isEmpty) return;
    final updated = [..._students];
    updated[index] = Student(name: name, birthDate: birth);
    await StudentStore.instance.saveStudents(updated);
    if (!mounted) return;
    setState(() {
      _students = updated;
    });
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      helpText: _byMonth ? 'اختيار شهر' : 'اختيار يوم',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  List<StatRecord> _filteredStats() {
    if (_stats.isEmpty) return [];
    final yyyy = _selectedDate.year.toString().padLeft(4, '0');
    final mm = _selectedDate.month.toString().padLeft(2, '0');
    final dd = _selectedDate.day.toString().padLeft(2, '0');
    final dayKey = '$yyyy-$mm-$dd';
    if (_byMonth) {
      final monthKey = '$yyyy-$mm';
      return _stats.where((s) => s.date.startsWith(monthKey)).toList();
    }
    return _stats.where((s) => s.date == dayKey).toList();
  }

  List<StatRecord> _sortedStats() {
    final rows = [..._filteredStats()];
    rows.sort((a, b) {
      int cmp;
      switch (_sortKey) {
        case _SortKey.duration:
          cmp = a.durationSeconds.compareTo(b.durationSeconds);
          break;
        case _SortKey.errors:
          cmp = a.errors.compareTo(b.errors);
          break;
        case _SortKey.date:
        default:
          cmp = _parseDate(a.date).compareTo(_parseDate(b.date));
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return rows;
  }

  DateTime _parseDate(String value) {
    try {
      final parts = value.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      if (parts.length == 2) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      }
    } catch (_) {}
    return DateTime(1970);
  }

  Future<void> _exportExcel() async {
    final student = _students.isNotEmpty ? _students.first : null;
    final data = _filteredStats();
    final excel = xls.Excel.createExcel();
    final sheet = excel['stats'];

    sheet.appendRow([
      'اسم التلميذ',
      student?.name ?? '',
      'تاريخ الميلاد',
      student?.birthDate ?? '',
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      _byMonth ? 'شهر' : 'تاريخ',
      'اللعبة',
      'الوقت',
      'الأخطاء',
      'الإجابات الصحيحة',
    ]);

    for (final s in data) {
      sheet.appendRow([
        s.date,
        _gameLabel(s.gameKey),
        s.durationSeconds,
        s.errors,
        s.correct,
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final yyyy = _selectedDate.year.toString().padLeft(4, '0');
    final mm = _selectedDate.month.toString().padLeft(2, '0');
    final dd = _selectedDate.day.toString().padLeft(2, '0');
    final suffix = _byMonth ? '$yyyy-$mm' : '$yyyy-$mm-$dd';
    final file = File('${dir.path}/stats_$suffix.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ الملف: ${file.path}')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'لوحة المعلمة',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.almarai(
                            fontSize: isTablet ? 30 : 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E212D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 20),
                        if (_students.isEmpty) ...[
                          _buildForm(isTablet),
                          const SizedBox(height: 16),
                          _buildEmptyState(),
                        ] else ...[
                          _buildProfile(isTablet),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildFilterBar(isTablet),
                          ),
                          const SizedBox(height: 18),
                          _sectionTitle('ملخص الفترة', isTablet),
                          const SizedBox(height: 10),
                          _buildSummary(_filteredStats(), isTablet),
                          const SizedBox(height: 18),
                          _sectionTitle('الجدول التفصيلي', isTablet),
                          const SizedBox(height: 10),
                          _buildStatsTable(isTablet),
                          const SizedBox(height: 18),
                          _sectionTitle('الرسوم البيانية', isTablet),
                          const SizedBox(height: 10),
                          _buildCharts(_filteredStats(), isTablet),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(bool isTablet) {
    final student = _students.first;
    final today = DateTime.now();
    final yyyy = today.year.toString().padLeft(4, '0');
    final mm = today.month.toString().padLeft(2, '0');
    final dd = today.day.toString().padLeft(2, '0');
    final todayLabel = '$yyyy-$mm-$dd';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ملف التلميذ',
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E212D),
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('الاسم', student.name, isTablet),
          _infoRow('تاريخ الميلاد', student.birthDate, isTablet),
          _infoRow('تاريخ اليوم', todayLabel, isTablet),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _editStudent(0),
              child: Text(
                'تعديل البيانات',
                style: GoogleFonts.almarai(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _removeStudent(0),
              child: Text(
                'تغيير التلميذ',
                style: GoogleFonts.almarai(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E212D),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF1E212D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTable(bool isTablet) {
    final rows = _sortedStats();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _headerSortCell(
                    label: 'تاريخ',
                    align: TextAlign.right,
                    key: _SortKey.date,
                  ),
                ),
                Expanded(child: _headerCell('اللعبة', TextAlign.right)),
                Expanded(
                  child: _headerSortCell(
                    label: 'الوقت',
                    align: TextAlign.center,
                    key: _SortKey.duration,
                  ),
                ),
                Expanded(
                  child: _headerSortCell(
                    label: 'الأخطاء',
                    align: TextAlign.center,
                    key: _SortKey.errors,
                  ),
                ),
                Expanded(child: _headerCell('الإجابات', TextAlign.center)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isTablet ? 320 : 240,
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد بيانات لعب بعد',
                      style: GoogleFonts.almarai(
                        fontSize: isTablet ? 15 : 14,
                        color: const Color(0xFF1E212D),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = rows[index];
                      final zebra = index.isEven
                          ? const Color(0xFFF7F9FC)
                          : Colors.transparent;
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: zebra,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _cell(s.date, TextAlign.right)),
                            Expanded(child: _cell(_gameLabel(s.gameKey), TextAlign.right)),
                            Expanded(
                              child: _cell(
                                _formatDuration(s.durationSeconds),
                                TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: _cell(s.errors.toString(), TextAlign.center),
                            ),
                            Expanded(
                              child: _cell(s.correct.toString(), TextAlign.center),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterButton(
            label: 'يومي',
            selected: !_byMonth,
            onTap: () => setState(() => _byMonth = false),
          ),
          _filterButton(
            label: 'شهري',
            selected: _byMonth,
            onTap: () => setState(() => _byMonth = true),
          ),
          _filterButton(
            label: 'اختيار تاريخ',
            selected: false,
            onTap: _pickFilterDate,
          ),
          _filterButton(
            label: 'تصدير Excel',
            selected: false,
            onTap: _exportExcel,
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(List<StatRecord> rows, bool isTablet) {
    final correctByGame = _aggregateByGame(rows);
    final daily = _aggregateByDay(rows);
    final totalCorrect =
        rows.fold<int>(0, (sum, r) => sum + r.correct);
    final totalErrors =
        rows.fold<int>(0, (sum, r) => sum + r.errors);

    final chartHeight = isTablet ? 240.0 : 210.0;
    return Column(
      children: [
        _chartCard(
          title: 'أفضل الألعاب أداءً',
          height: chartHeight,
          child: _barChart(correctByGame),
        ),
        if (_byMonth) ...[
          const SizedBox(height: 12),
          _chartCard(
            title: 'تطور الأداء حسب الأيام',
            height: chartHeight,
            child: _lineChart(daily),
          ),
        ],
        const SizedBox(height: 12),
        _chartCard(
          title: 'نسبة الصحيح مقابل الخطأ',
          height: chartHeight,
          child: _pieChart(totalCorrect, totalErrors),
        ),
      ],
    );
  }

  Widget _buildSummary(List<StatRecord> rows, bool isTablet) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'لا توجد بيانات لعب بعد',
          style: GoogleFonts.almarai(
            fontSize: isTablet ? 15 : 14,
            color: const Color(0xFF1E212D),
          ),
        ),
      );
    }

    final totals = <String, List<StatRecord>>{};
    for (final r in rows) {
      totals.putIfAbsent(r.gameKey, () => []).add(r);
    }

    int totalPlays = rows.length;
    int totalErrors =
        rows.fold(0, (sum, r) => sum + r.errors);
    int totalCorrect =
        rows.fold(0, (sum, r) => sum + r.correct);
    int totalSeconds =
        rows.fold(0, (sum, r) => sum + r.durationSeconds);
    final avgSeconds =
        totalPlays == 0 ? 0 : (totalSeconds / totalPlays).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = isTablet ? 12.0 : 10.0;
          final cardWidth = (constraints.maxWidth - gap) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                      icon: Icons.videogame_asset_rounded,
                      title: 'عدد الألعاب',
                      value: '$totalPlays',
                      color: const Color(0xFF4DA3FF),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                      icon: Icons.check_circle_rounded,
                      title: 'الإجابات الصحيحة',
                      value: '$totalCorrect',
                      color: const Color(0xFF6DD96C),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                      icon: Icons.error_rounded,
                      title: 'الأخطاء',
                      value: '$totalErrors',
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                      icon: Icons.timer_rounded,
                      title: 'متوسط الوقت',
                      value: _formatDuration(avgSeconds),
                      color: const Color(0xFFFF8A3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...totals.entries.map((entry) {
                final key = entry.key;
                final list = entry.value;
                final plays = list.length;
                final wins = _countWins(key, list);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _cell(_gameLabel(key), TextAlign.right)),
                      Expanded(child: _cell('لعب: $plays', TextAlign.center)),
                      Expanded(child: _cell('فاز: $wins', TextAlign.center)),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  int _countWins(String gameKey, List<StatRecord> list) {
    final target = _winTarget(gameKey);
    if (target == null) return 0;
    return list.where((r) => r.correct >= target).length;
  }

  int? _winTarget(String gameKey) {
    switch (gameKey) {
      case 'memory':
        return 4;
      case 'color':
        return 6;
      case 'numbers':
        return 9;
      case 'letters':
        return 28;
      case 'family':
        return 15;
      case 'fruits_veg':
        return 8;
      case 'puzzle':
        return 33;
      case 'listen_name':
        return 20;
      case 'word_build':
        return 12;
      case 'tracing':
        return 4;
      case 'tap_target':
        return 30;
      case 'emotions':
        return 15;
      case 'compare':
        return 15;
      case 'fruits':
        return 10;
      default:
        return null;
    }
  }

  String _gameLabel(String key) {
    switch (key) {
      case 'color':
        return 'الألوان';
      case 'memory':
        return 'ميمو';
      case 'numbers':
        return 'الأرقام';
      case 'letters':
        return 'الحروف';
      case 'family':
        return 'العائلة';
      case 'fruits_veg':
        return 'الفواكه والخضروات';
      case 'puzzle':
        return 'ركّب الصورة';
      case 'listen_name':
        return 'اسمع وسمّي';
      case 'word_build':
        return 'ركّب الكلمة';
      case 'tracing':
        return 'اتبع الخط';
      case 'tap_target':
        return 'اضغط على الهدف';
      case 'emotions':
        return 'كيف أشعر؟';
      case 'compare':
        return 'أيهما أكبر؟';
      case 'fruits':
        return 'الفواكه';
      default:
        return key;
    }
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.almarai(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E212D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.almarai(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E212D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color(0x11000000),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4DA3FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF4DA3FF) : const Color(0xFFE2E6EA),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.almarai(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF1E212D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text, TextAlign align) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.almarai(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E212D),
      ),
    );
  }

  Widget _headerSortCell({
    required String label,
    required TextAlign align,
    required _SortKey key,
  }) {
    final isActive = _sortKey == key;
    final icon = isActive
        ? (_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
        : Icons.swap_vert_rounded;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortKey == key) {
            _sortAsc = !_sortAsc;
          } else {
            _sortKey = key;
            _sortAsc = true;
          }
        });
      },
      child: Row(
        mainAxisAlignment:
            align == TextAlign.right ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.almarai(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E212D),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 16,
            color: isActive ? const Color(0xFF4DA3FF) : const Color(0xFF9AA3AD),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, TextAlign align) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.almarai(
        fontSize: 12.5,
        color: const Color(0xFF1E212D),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isTablet) {
    return Text(
      text,
      style: GoogleFonts.almarai(
        fontSize: isTablet ? 20 : 17,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E212D),
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required double height,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.almarai(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E212D),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Map<String, int> _aggregateByGame(List<StatRecord> rows) {
    final map = <String, int>{};
    for (final r in rows) {
      map[r.gameKey] = (map[r.gameKey] ?? 0) + r.correct;
    }
    return map;
  }

  List<_DayPoint> _aggregateByDay(List<StatRecord> rows) {
    final map = <String, int>{};
    for (final r in rows) {
      map[r.date] = (map[r.date] ?? 0) + r.correct;
    }
    final keys = map.keys.toList()..sort();
    return keys.map((k) => _DayPoint(k, map[k] ?? 0)).toList();
  }

  Widget _barChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.fold<int>(1, (m, e) => math.max(m, e.value));
    const palette = [
      Color(0xFF4DA3FF),
      Color(0xFF6DD96C),
      Color(0xFFFFD45A),
      Color(0xFFFF8A3D),
      Color(0xFFFF6B6B),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFFF472B6),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 26.0;
        final spacing = 14.0;
        final contentWidth =
            math.max(constraints.maxWidth, entries.length * (barWidth + spacing));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: entries.length <= 5
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final barHeight =
                    (constraints.maxHeight - 36) * (e.value / maxVal);
                final color = palette[idx % palette.length];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: SizedBox(
                    width: barWidth + 18,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _gameLabel(e.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.almarai(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _lineChart(List<_DayPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final offsets = _computeLineOffsets(points, size);
        final safeIndex = (_lineHoverIndex != null &&
                _lineHoverIndex! >= 0 &&
                _lineHoverIndex! < points.length)
            ? _lineHoverIndex
            : null;
        final safeOffset =
            safeIndex == null ? null : offsets[safeIndex];
        return GestureDetector(
          onTapDown: (details) {
            final local = details.localPosition;
            final idx = _nearestPointIndex(local, offsets);
            setState(() {
              _lineHoverIndex = idx;
              _lineHoverOffset = offsets[idx];
            });
          },
          child: Stack(
            children: [
              CustomPaint(
                painter: _LineChartPainter(points),
                child: const SizedBox.expand(),
              ),
              if (safeIndex != null && safeOffset != null)
                Positioned(
                  left: (safeOffset.dx - 50)
                      .clamp(0.0, size.width - 100),
                  top: (safeOffset.dy - 40)
                      .clamp(0.0, size.height - 40),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${points[safeIndex].day} • ${points[safeIndex].value}',
                      style: GoogleFonts.almarai(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E212D),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _pieChart(int correct, int errors) {
    final total = correct + errors;
    if (total == 0) {
      return const Center(child: Text('لا توجد بيانات'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 420;
        final chartSize =
            math.min(constraints.maxHeight, constraints.maxWidth * 0.55);
        final percent = ((correct / total) * 100).round();
        final pie = SizedBox(
          width: chartSize,
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    correct.toDouble(),
                    errors.toDouble(),
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.almarai(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E212D),
                ),
              ),
            ],
          ),
        );
        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem('الإجابات الصحيحة', correct, total,
                const Color(0xFF6DD96C)),
            const SizedBox(height: 8),
            _legendItem('الأخطاء', errors, total, const Color(0xFFFF6B6B)),
          ],
        );
        return isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  pie,
                  legend,
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  pie,
                  const SizedBox(height: 10),
                  legend,
                ],
              );
      },
    );
  }

  List<Offset> _computeLineOffsets(List<_DayPoint> points, Size size) {
    final pad = 12.0;
    final maxVal =
        points.fold<int>(1, (m, p) => math.max(m, p.value));
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;
    return List.generate(points.length, (i) {
      final dx = points.length == 1
          ? size.width / 2
          : pad + width * (i / (points.length - 1));
      final dy = pad + height * (1 - (points[i].value / maxVal));
      return Offset(dx, dy);
    });
  }

  int _nearestPointIndex(Offset p, List<Offset> pts) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < pts.length; i++) {
      final d = (pts[i] - p).distance;
      if (d < bestDist) {
        best = i;
        bestDist = d;
      }
    }
    return best;
  }

  Widget _legendItem(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percent = total == 0 ? 0 : ((value / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($percent%)',
          style: GoogleFonts.almarai(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E212D),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '${totalSeconds} ثانية';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes دقيقة';
    }
    return '$minutes دقيقة ${seconds} ثانية';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'أضف تلميذًا للبدء',
        style: GoogleFonts.almarai(
          fontSize: 16,
          color: const Color(0xFF1E212D),
        ),
      ),
    );
  }

  Widget _buildForm(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'اسم التلميذ',
              border: InputBorder.none,
            ),
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 18 : 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Divider(height: 16),
          TextField(
            controller: _birthController,
            decoration: const InputDecoration(
              hintText: 'تاريخ الميلاد',
              border: InputBorder.none,
            ),
            style: GoogleFonts.almarai(
              fontSize: isTablet ? 18 : 16,
            ),
            textDirection: TextDirection.rtl,
            readOnly: true,
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addStudent,
              child: Text(
                'إضافة',
                style: GoogleFonts.almarai(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() => const SizedBox.shrink();
}

enum _SortKey { date, duration, errors }

class _DayPoint {
  final String day;
  final int value;
  const _DayPoint(this.day, this.value);
}

class _LineChartPainter extends CustomPainter {
  final List<_DayPoint> points;
  _LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final pad = 12.0;
    final maxVal =
        points.fold<int>(1, (m, p) => math.max(m, p.value));
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;

    final gridPaint = Paint()
      ..color = const Color(0xFFE6EAF0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = pad + height * (i / 4);
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), gridPaint);
    }

    final gradient = const LinearGradient(
      colors: [Color(0xFF9AE6B4), Color(0xFF38A169)],
    );
    final paintLine = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paintDot = Paint()
      ..color = const Color(0xFF38A169)
      ..style = PaintingStyle.fill;
    final paintDotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : pad + width * (i / (points.length - 1));
      final y = pad + height * (1 - (points[i].value / maxVal));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : pad + width * (i / (points.length - 1));
      final y = pad + height * (1 - (points[i].value / maxVal));
      canvas.drawCircle(Offset(x, y), 5.5, paintDotBorder);
      canvas.drawCircle(Offset(x, y), 3.8, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final double correct;
  final double errors;
  _PieChartPainter(this.correct, this.errors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = correct + errors;
    if (total == 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -math.pi / 2;
    final sweepCorrect = (correct / total) * math.pi * 2;
    final paintCorrect = Paint()
      ..color = const Color(0xFF6DD96C)
      ..style = PaintingStyle.fill;
    final paintErrors = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, startAngle, sweepCorrect, true, paintCorrect);
    canvas.drawArc(
      rect,
      startAngle + sweepCorrect,
      math.pi * 2 - sweepCorrect,
      true,
      paintErrors,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
