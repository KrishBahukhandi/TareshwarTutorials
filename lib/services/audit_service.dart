import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Service for logging admin actions for compliance and debugging
class AuditService {
  /// Log an admin action to the audit_logs table
  Future<void> logAction({
    required String action, // 'create', 'update', 'delete', 'activate', 'deactivate', 'enroll', 'unenroll'
    required String resourceType, // 'student', 'teacher', 'course', 'batch', 'enrollment', 'content'
    required String resourceId,
    String? resourceName,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user for audit logging');
      }

      // Get admin email from current session
      final adminEmail = currentUser.email ?? 'unknown@admin';

      await supabase.from('admin_audit_logs').insert({
        'admin_id': currentUser.id,
        'admin_email': adminEmail,
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'resource_name': resourceName,
        'old_data': oldData != null ? jsonEncode(oldData) : null,
        'new_data': newData != null ? jsonEncode(newData) : null,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      });
    } catch (e) {
      // Log failure silently - don't block the main operation
      print('Audit logging failed: $e');
    }
  }

  /// Fetch recent audit logs (admin only)
  Future<List<Map<String, dynamic>>> fetchRecentLogs({
    int limit = 50,
    String? resourceType,
    String? action,
  }) async {
    try {
      var query = supabase
          .from('admin_audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // Apply filters if provided
      if (resourceType != null && action != null) {
        // Both filters
        final response = await supabase
            .from('admin_audit_logs')
            .select()
            .eq('resource_type', resourceType)
            .eq('action', action)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else if (resourceType != null) {
        final response = await supabase
            .from('admin_audit_logs')
            .select()
            .eq('resource_type', resourceType)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else if (action != null) {
        final response = await supabase
            .from('admin_audit_logs')
            .select()
            .eq('action', action)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  /// Get audit logs for a specific resource
  Future<List<Map<String, dynamic>>> fetchLogsForResource({
    required String resourceType,
    required String resourceId,
  }) async {
    try {
      final response = await supabase
          .from('admin_audit_logs')
          .select()
          .eq('resource_type', resourceType)
          .eq('resource_id', resourceId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch resource audit logs: $e');
    }
  }

  /// Get audit logs by admin
  Future<List<Map<String, dynamic>>> fetchLogsByAdmin(String adminId) async {
    try {
      final response = await supabase
          .from('admin_audit_logs')
          .select()
          .eq('admin_id', adminId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch admin logs: $e');
    }
  }

  /// Get audit log statistics
  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      // Get all logs and count them in memory (for now)
      final allLogs = await supabase
          .from('admin_audit_logs')
          .select();

      final List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(allLogs);

      // Count by action type
      final createCount = logs.where((log) => log['action'] == 'create').length;
      final updateCount = logs.where((log) => log['action'] == 'update').length;
      final deleteCount = logs.where((log) => log['action'] == 'delete').length;

      return {
        'total': logs.length,
        'creates': createCount,
        'updates': updateCount,
        'deletes': deleteCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch audit stats: $e');
    }
  }
}
