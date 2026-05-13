import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';

class RouteGuards {
  RouteGuards._();

  /// Check if user is authenticated
  static String? authGuard(BuildContext context, GoRouterState state) {
    final isAuthenticated = SupabaseService.isAuthenticated;
    if (!isAuthenticated) return '/login';
    return null;
  }

  /// Check if user has a specific role
  static Future<bool> hasRole(String requiredRole) async {
    final profile = await SupabaseService.getCurrentProfile();
    if (profile == null) return false;
    return profile['role'] == requiredRole;
  }

  /// Check if user is owner
  static Future<bool> isOwner() async {
    return await hasRole('owner');
  }

  /// Check if user is owner or warehouse manager
  static Future<bool> isManagerOrAbove() async {
    final profile = await SupabaseService.getCurrentProfile();
    if (profile == null) return false;
    final role = profile['role'] as String?;
    return role == 'owner' || role == 'warehouse_manager';
  }
}
