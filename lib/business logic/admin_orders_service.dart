import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/business%20logic/models/admin_order_model.dart';
import 'package:flutter/material.dart';

class AdminOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OrderStatistics> getOrderStatistics() async {
    try {
      QuerySnapshot ordersSnapshot =
          await _firestore.collection('orders').get();

      double totalRevenue = 0;
      Map<String, int> statusCounts = {
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'pending';
        final total = data['total'] as double? ?? 0.0;

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        totalRevenue += total;
      }

      return OrderStatistics(
        total: ordersSnapshot.docs.length,
        statusCounts: statusCounts,
        totalRevenue: totalRevenue,
      );
    } catch (e) {
      print('Error loading order statistics: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getOrders({
    String status = 'all',
    DateTime? startDate,
    DateTime? endDate,
    String timeRange = 'all',
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('orders').orderBy('created_at', descending: true);

    if (status != 'all') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    if (startDate != null && endDate != null) {
      final adjustedEndDate = endDate
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));
      query = query
          .where('created_at', isGreaterThanOrEqualTo: startDate)
          .where('created_at', isLessThanOrEqualTo: adjustedEndDate);
    } else if (timeRange != 'all') {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final ranges = {
        'today': 0,
        'week': 7,
        'month': 30,
        'year': 365,
      };

      if (ranges.containsKey(timeRange)) {
        final startDate =
            startOfDay.subtract(Duration(days: ranges[timeRange]!));
        query = query.where('created_at', isGreaterThanOrEqualTo: startDate);
      }
    }

    return query.snapshots();
  }

  Future<void> updateOrderStatus(
      BuildContext context, Map<String, dynamic> orderData,
      {bool showUI = true}) async {
    try {
      final orderId = orderData['order_id'];
      final newStatus = orderData['new_status'] as String;

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (context.mounted && showUI) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      if (context.mounted && showUI) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }
}
