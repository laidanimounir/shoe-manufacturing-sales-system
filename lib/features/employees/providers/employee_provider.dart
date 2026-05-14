import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../data/salary_sheet_model.dart';
import '../data/salary_repository.dart';

final employeeSearchProvider = StateProvider<String>((ref) => '');
final employeeActiveFilterProvider = StateProvider<String?>((ref) => null);

final employeesProvider =
    FutureProvider.family<List<Employee>, void>((ref, _) async {
  final search = ref.watch(employeeSearchProvider);
  final filter = ref.watch(employeeActiveFilterProvider);
  return EmployeeRepository.getAll(
    search: search.isNotEmpty ? search : null,
    isActive: filter == 'all' ? null : filter == 'active' ? true : false,
  );
});

final employeeDetailProvider =
    FutureProvider.family<Employee?, String>((ref, id) async {
  return EmployeeRepository.getById(id);
});

final todayAttendanceProvider =
    FutureProvider<List<Attendance>>((ref) async {
  return AttendanceRepository.getTodayAttendance();
});

final monthAttendanceProvider =
    FutureProvider.family<List<Attendance>, ({int year, int month})>(
  (ref, params) async {
    return AttendanceRepository.getByMonth(params.year, params.month);
  },
);

final salarySheetProvider =
    FutureProvider.family<List<SalarySheet>, ({int year, int month})>(
  (ref, params) async {
    return SalaryRepository.getAll(year: params.year, month: params.month);
  },
);

final monthlyReportProvider =
    FutureProvider.family<Map<String, dynamic>, ({int year, int month})>(
  (ref, params) async {
    return SalaryRepository.getMonthlyReport(params.year, params.month);
  },
);
