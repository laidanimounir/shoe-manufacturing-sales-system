import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isCalendarLoading = false;
  List<Attendance> _todayAttendance = [];
  List<Attendance> _monthAttendance = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index == 1 &&
          _monthAttendance.isEmpty) {
        _loadMonth();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    setState(() => _isLoading = true);
    try {
      final data = await AttendanceRepository.getTodayAttendance();
      if (mounted) {
        setState(() {
          _todayAttendance = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: $e');
      }
    }
  }

  Future<void> _loadMonth() async {
    if (_isCalendarLoading) return;
    setState(() => _isCalendarLoading = true);
    try {
      final data =
          await AttendanceRepository.getByMonth(_selectedYear, _selectedMonth);
      if (mounted) {
        setState(() {
          _monthAttendance = data;
          _isCalendarLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalendarLoading = false);
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(m)),
        ]),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  Future<void> _updateStatus(Attendance a, String newStatus) async {
    setState(() {
      _todayAttendance = _todayAttendance.map((e) {
        if (e.employeeId == a.employeeId) {
          return Attendance(
            id: e.id,
            employeeId: e.employeeId,
            employeeName: e.employeeName,
            workDate: e.workDate,
            status: newStatus,
            notes: e.notes,
            createdAt: e.createdAt,
          );
        }
        return e;
      }).toList();
    });
    try {
      final updated = Attendance(
        id: a.id,
        employeeId: a.employeeId,
        employeeName: a.employeeName,
        workDate: a.workDate,
        status: newStatus,
        notes: a.notes,
        createdAt: a.createdAt,
      );
      await AttendanceRepository.upsert(updated);
      await _loadToday();
    } catch (e) {
      _showError('Erreur: $e');
      await _loadToday();
    }
  }

  Color _statusColor(String status, {required bool isDark}) {
    switch (status) {
      case 'present':
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case 'absent':
        return isDark ? AppColors.darkError : AppColors.lightError;
      case 'late':
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case 'half_day':
        return isDark ? AppColors.darkInfo : AppColors.lightInfo;
      case 'holiday':
        return isDark ? AppColors.darkMuted : AppColors.lightMuted;
      default:
        return isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pointage du jour'),
            Tab(text: 'Calendrier mensuel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(theme, isDark),
          _buildCalendarTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildTodayTab(ThemeData theme, bool isDark) {
    final present =
        _todayAttendance.where((a) => a.status == 'present').length;
    final absent =
        _todayAttendance.where((a) => a.status == 'absent').length;
    final late = _todayAttendance.where((a) => a.status == 'late').length;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Aujourd'hui", style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem(
                        '$present',
                        'Présents',
                        isDark
                            ? AppColors.darkSuccess
                            : AppColors.lightSuccess),
                    Text('/',
                        style: TextStyle(
                            color: theme.textTheme.bodySmall?.color)),
                    _summaryItem(
                        '$absent',
                        'Absents',
                        isDark ? AppColors.darkError : AppColors.lightError),
                    Text('/',
                        style: TextStyle(
                            color: theme.textTheme.bodySmall?.color)),
                    _summaryItem(
                        '$late',
                        'En retard',
                        isDark ? AppColors.darkWarning : AppColors.lightWarning),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                _buildShimmerContent(isDark)
              else if (_todayAttendance.isEmpty)
                _buildEmpty(theme, Icons.event_busy, "Aucun pointage pour aujourd'hui")
              else
                ..._todayAttendance
                    .map((a) => _buildAttendanceCard(a, theme, isDark)),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Widget _buildAttendanceCard(Attendance a, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.employeeName ?? 'Inconnu',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _buildStatusButton(
                    'Présent', 'present', a.status, isDark, () => _updateStatus(a, 'present')),
                const SizedBox(width: 4),
                _buildStatusButton(
                    'Absent', 'absent', a.status, isDark, () => _updateStatus(a, 'absent')),
                const SizedBox(width: 4),
                _buildStatusButton(
                    'Retard', 'late', a.status, isDark, () => _updateStatus(a, 'late')),
                const SizedBox(width: 4),
                _buildStatusButton(
                    'Demi-J', 'half_day', a.status, isDark, () => _updateStatus(a, 'half_day')),
                const SizedBox(width: 4),
                _buildStatusButton(
                    'Congé', 'holiday', a.status, isDark, () => _updateStatus(a, 'holiday')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, String currentStatus,
      bool isDark, VoidCallback onTap) {
    final isSelected = status == currentStatus;
    final color = _statusColor(status, isDark: isDark);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withValues(alpha: 0.15) : null,
        side: BorderSide(color: isSelected ? color : Colors.transparent),
        foregroundColor:
            isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildCalendarTab(ThemeData theme, bool isDark) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendrier mensuel', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('month_$_selectedMonth'),
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mois',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12,
                        (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedMonth = v;
                          _monthAttendance = [];
                        });
                        _loadMonth();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('year_$_selectedYear'),
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                          value: DateTime.now().year - 5 + i,
                          child: Text('${DateTime.now().year - 5 + i}')),
                    ),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedYear = v;
                          _monthAttendance = [];
                        });
                        _loadMonth();
                      }
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (_isCalendarLoading)
                _buildShimmerContent(isDark)
              else if (_monthAttendance.isEmpty)
                _buildEmpty(theme, Icons.calendar_month, 'Aucune donnée pour ce mois')
              else
                _buildCalendarTable(theme, isDark),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Widget _buildCalendarTable(ThemeData theme, bool isDark) {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final employees = _getUniqueEmployees();
    final attendanceMap = _groupAttendanceByEmployee();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        headingRowHeight: 36,
        columns: [
          const DataColumn(
              label: Text('Employé',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          ...List.generate(
            daysInMonth,
            (i) => DataColumn(
                label: Text('${i + 1}', style: const TextStyle(fontSize: 10))),
          ),
          const DataColumn(
              label: Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w600))),
        ],
        rows: employees.map((entry) {
          final employeeId = entry.key;
          final employeeName = entry.value ?? 'Inconnu';
          final days = attendanceMap[employeeId] ?? {};
          int present = 0, late = 0, half = 0;
          for (final s in days.values) {
            if (s == 'present') present++;
            if (s == 'late') late++;
            if (s == 'half_day') half++;
          }
          final total = present + late + half ~/ 2;

          return DataRow(cells: [
            DataCell(Text(employeeName, style: const TextStyle(fontSize: 11))),
            ...List.generate(daysInMonth, (i) {
              final day = i + 1;
              final status = days[day];
              return DataCell(_buildDayCell(status, isDark));
            }),
            DataCell(Text('$total',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(String? status, bool isDark) {
    if (status == null) {
      return const SizedBox(width: 16, height: 16);
    }
    final color = _statusColor(status, isDark: isDark);
    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Map<String, Map<int, String>> _groupAttendanceByEmployee() {
    final map = <String, Map<int, String>>{};
    for (final a in _monthAttendance) {
      map.putIfAbsent(a.employeeId, () => {})[a.workDate.day] = a.status;
    }
    return map;
  }

  List<MapEntry<String, String?>> _getUniqueEmployees() {
    final seen = <String>{};
    final list = <MapEntry<String, String?>>[];
    for (final a in _monthAttendance) {
      if (seen.add(a.employeeId)) {
        list.add(MapEntry(a.employeeId, a.employeeName));
      }
    }
    return list;
  }

  Widget _summaryItem(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 48, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
        ]),
      ),
    );
  }

  Widget _buildShimmerContent(bool isDark) {
    return Shimmer.fromColors(
      baseColor:
          isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor:
          isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: Column(
        children: List.generate(5, (i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
          ),
        )),
      ),
    );
  }
}
