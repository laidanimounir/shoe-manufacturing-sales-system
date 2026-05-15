import 'package:intl/intl.dart';

class AuditLog {
  final String id;
  final String? userId;
  final String userName;
  final String action;
  final String tableName;
  final String? recordId;
  final String description;
  final DateTime? createdAt;

  const AuditLog({
    required this.id,
    this.userId,
    required this.userName,
    required this.action,
    required this.tableName,
    this.recordId,
    required this.description,
    this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    String userName = map['user_name'] as String? ?? 'Système';
    final pr = map['profiles'];
    if (pr is Map) {
      userName = pr['full_name'] as String? ?? userName;
    }
    return AuditLog(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      userName: userName,
      action: map['action'] as String,
      tableName: map['table_name'] as String? ?? '',
      recordId: map['record_id'] as String?,
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  String get actionLabel {
    switch (action) {
      case 'create': return 'Création';
      case 'update': return 'Modification';
      case 'delete': return 'Suppression';
      case 'approve': return 'Approbation';
      case 'payment': return 'Paiement';
      case 'transfer': return 'Transfert';
      default: return action;
    }
  }

  String get formattedDate {
    if (createdAt == null) return '-';
    return '${DateFormat('dd/MM/yyyy').format(createdAt!)} à ${DateFormat('HH:mm').format(createdAt!)}';
  }

  @override
  String toString() => 'AuditLog($action, $tableName)';
}
