class AppStrings {
  AppStrings._();

  static const String appName = 'ShoeTrak';
  static const String appTagline = 'Système ERP de fabrication de chaussures';

  // Roles
  static const Map<String, String> roleLabelsFr = {
    'owner': 'Propriétaire',
    'warehouse_manager': 'Chef de dépôt',
    'salesperson': 'Vendeur',
    'accountant': 'Comptable',
    'stock_keeper': 'Magasinier',
    'production_worker': 'Ouvrier de production',
  };

  static const Map<String, String> roleLabelsAr = {
    'owner': 'المالك',
    'warehouse_manager': 'مسؤول المستودع',
    'salesperson': 'بائع',
    'accountant': 'محاسب',
    'stock_keeper': 'أمين المخزن',
    'production_worker': 'عامل إنتاج',
  };

  // Payment statuses
  static const Map<String, String> paymentStatusFr = {
    'paid': 'Payé',
    'partial': 'Partiel',
    'unpaid': 'Impayé',
  };

  // Production statuses
  static const Map<String, String> productionStatusFr = {
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminé',
    'cancelled': 'Annulé',
  };

  // Currency
  static const String currency = 'DZD';
  static const String currencySymbol = 'د.ج';
}
