import 'dart:math';
import '../../../core/services/supabase_service.dart';
import 'invoice_model.dart';
import 'invoice_item_model.dart';

class InvoiceRepository {
  static const _table = 'invoices';
  static const _itemsTable = 'invoice_items';
  static const _paymentsTable = 'payments';
  static const _clientsTable = 'clients';
  static const _inventoryTable = 'inventory';

  static Future<List<Invoice>> getAll({
    String? clientId,
    String? status,
    String? warehouseId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, clients(name), warehouses(name), profiles!invoices_sold_by_fkey(full_name)');

    if (clientId != null && clientId.isNotEmpty) {
      query = query.eq('client_id', clientId);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('payment_status', status);
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }
    if (dateFrom != null) {
      query = query.gte('invoice_date', dateFrom.toIso8601String().split('T').first);
    }
    if (dateTo != null) {
      query = query.lte('invoice_date', dateTo.toIso8601String().split('T').first);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('invoice_number.ilike.%$search%,clients.name.ilike.%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => Invoice.fromMap(json)).toList();
  }

  static Future<Invoice?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, clients(name), warehouses(name), profiles!invoices_sold_by_fkey(full_name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Invoice.fromMap(response);
  }

  static Future<List<InvoiceItem>> getItems(String invoiceId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_itemsTable)
        .select('*, products(name, sku)')
        .eq('invoice_id', invoiceId)
        .order('id');
    return (data as List).map((json) => InvoiceItem.fromMap(json)).toList();
  }

  static Future<List<Invoice>> getTodaySales({String? warehouseId}) async {
    final client = SupabaseService.client;
    final today = DateTime.now().toIso8601String().split('T').first;
    var query = client
        .from(_table)
        .select('*, clients(name), warehouses(name), profiles!invoices_sold_by_fkey(full_name)')
        .gte('invoice_date', today)
        .lte('invoice_date', today);

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => Invoice.fromMap(json)).toList();
  }

  static Future<Map<String, dynamic>> getDailySummary({
    String? warehouseId,
  }) async {
    final client = SupabaseService.client;
    final today = DateTime.now().toIso8601String().split('T').first;
    var query = client.from(_table).select('total_amount, paid_amount').gte('invoice_date', today).lte('invoice_date', today);

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }

    final data = await query;
    double totalRevenue = 0;
    double totalPaid = 0;
    double totalDebt = 0;
    int count = (data as List).length;

    for (final row in data) {
      totalRevenue += (row['total_amount'] as num?)?.toDouble() ?? 0;
      totalPaid += (row['paid_amount'] as num?)?.toDouble() ?? 0;
    }
    totalDebt = totalRevenue - totalPaid;

    return {
      'totalRevenue': totalRevenue,
      'totalPaid': totalPaid,
      'totalDebt': totalDebt,
      'count': count,
    };
  }

  static Future<String> _generateInvoiceNumber() async {
    final client = SupabaseService.client;
    final year = DateTime.now().year.toString();
    final data = await client
        .from(_table)
        .select('invoice_number')
        .ilike('invoice_number', 'INV-$year-%')
        .order('invoice_number', ascending: false)
        .limit(1);

    int seq = 1;
    if ((data as List).isNotEmpty) {
      final last = data.first['invoice_number'] as String;
      final parts = last.split('-');
      if (parts.length == 3) {
        seq = (int.tryParse(parts[2]) ?? 0) + 1;
      }
    }

    return 'INV-$year-${seq.toString().padLeft(4, '0')}';
  }

  static Future<Invoice> create({
    required String? warehouseId,
    required String? clientId,
    required String saleType,
    required double totalAmount,
    double initialPayment = 0,
    String? paymentMethod,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = SupabaseService.client;
    final currentUserId = SupabaseService.currentUserId;

    final invoiceNumber = await _generateInvoiceNumber();
    final paidAmount = initialPayment;
    String status;
    if (paidAmount >= totalAmount) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    } else {
      status = 'unpaid';
    }

    final insertMap = {
      'invoice_number': invoiceNumber,
      'warehouse_id': warehouseId,
      'client_id': clientId,
      'sold_by': currentUserId,
      'sale_type': saleType,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();
    final invoiceId = response['id'] as String;

    if (items.isNotEmpty) {
      final itemMaps = items.map((item) {
        return {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'source_type': item['source_type'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'unit_cost': item['unit_cost'],
        };
      }).toList();

      await client.from(_itemsTable).insert(itemMaps);

      for (final item in items) {
        final pId = item['product_id'] as String;
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        if (pId.isNotEmpty && warehouseId != null && warehouseId.isNotEmpty) {
          final existingInv = await client
              .from(_inventoryTable)
              .select('id, quantity')
              .eq('warehouse_id', warehouseId)
              .eq('product_id', pId)
              .maybeSingle();

          if (existingInv != null) {
            final currentQty = (existingInv['quantity'] as num?)?.toInt() ?? 0;
            final newQty = max(0, currentQty - qty);
            await client
                .from(_inventoryTable)
                .update({'quantity': newQty})
                .eq('id', existingInv['id']);
          }
        }
      }
    }

    if (paidAmount > 0) {
      await client.from(_paymentsTable).insert({
        'invoice_id': invoiceId,
        'client_id': clientId,
        'amount': paidAmount,
        'payment_method': paymentMethod ?? 'cash',
      });

      await SupabaseService.logAudit(
        action: 'payment',
        tableName: _paymentsTable,
        description: 'Paiement à la vente: $paidAmount DZD',
      );
    }

    final remainingDebt = totalAmount - paidAmount;
    if (remainingDebt > 0 && clientId != null && clientId.isNotEmpty) {
      final existingClient = await client
          .from(_clientsTable)
          .select('total_debt')
          .eq('id', clientId)
          .single();
      final currentDebt = (existingClient['total_debt'] as num?)?.toDouble() ?? 0;
      await client
          .from(_clientsTable)
          .update({'total_debt': currentDebt + remainingDebt})
          .eq('id', clientId);
    }

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: invoiceId,
      newData: insertMap,
      description: 'Facture créée : $invoiceNumber',
    );

    final full = await client
        .from(_table)
        .select('*, clients(name), warehouses(name), profiles!invoices_sold_by_fkey(full_name)')
        .eq('id', invoiceId)
        .single();
    return Invoice.fromMap(full);
  }

  static Future<void> recordPayment({
    required String invoiceId,
    required String? clientId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    final client = SupabaseService.client;

    await client.from(_paymentsTable).insert({
      'invoice_id': invoiceId,
      'client_id': clientId,
      'amount': amount,
      'payment_method': method,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    final invoice = await client
        .from(_table)
        .select('paid_amount, total_amount')
        .eq('id', invoiceId)
        .single();
    final currentPaid = (invoice['paid_amount'] as num?)?.toDouble() ?? 0;
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
    final newPaid = currentPaid + amount;

    String newStatus;
    if (newPaid >= totalAmount) {
      newStatus = 'paid';
    } else if (newPaid > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    await client.from(_table).update({
      'paid_amount': newPaid,
      'payment_status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);

    if (clientId != null && clientId.isNotEmpty) {
      final existingClient = await client
          .from(_clientsTable)
          .select('total_debt')
          .eq('id', clientId)
          .single();
      final currentDebt = (existingClient['total_debt'] as num?)?.toDouble() ?? 0;
      final newDebt = (currentDebt - amount).clamp(0, double.infinity);
      await client
          .from(_clientsTable)
          .update({'total_debt': newDebt})
          .eq('id', clientId);
    }

    await SupabaseService.logAudit(
      action: 'payment',
      tableName: _paymentsTable,
      description: 'Paiement facture: $amount DZD',
    );
  }

  static Future<List<Map<String, dynamic>>> getPayments(String invoiceId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_paymentsTable)
        .select()
        .eq('invoice_id', invoiceId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
