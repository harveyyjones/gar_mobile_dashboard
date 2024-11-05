import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminOrderDetailScreen({required this.orderData});

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List<dynamic>;
    final deliveryAddress =
        orderData['delivery_address'] as Map<String, dynamic>;
    final userData = orderData['user_data'] as Map<String, dynamic>;
    final status = orderData['status'] as String;
    final orderId = orderData['order_id'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showActionSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(orderId, status),
            SizedBox(height: 24),
            _buildSection(
              title: 'Items',
              child: Column(
                children: [
                  ...items.map((item) => _buildOrderItem(item)),
                  Divider(height: 32),
                  _buildTotalSection(),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildSection(
              title: 'Customer Information',
              child: _buildCustomerInfo(userData),
            ),
            SizedBox(height: 24),
            _buildSection(
              title: 'Delivery Address',
              child: _buildAddressInfo(deliveryAddress),
            ),
            SizedBox(height: 24),
            _buildSection(
              title: 'Status History',
              child: _buildStatusHistory(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildOrderHeader(String orderId, String status) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, 8)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDate(orderData['created_at'] as Timestamp),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'processing':
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case 'shipped':
        color = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${item['quantity']} x ${item['price']} ${item['currency']}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item['price'] * item['quantity']).toStringAsFixed(2)} ${item['currency']}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Column(
      children: [
        _buildPriceRow('Subtotal', orderData['total']),
        SizedBox(height: 8),
        _buildPriceRow('Shipping', 0),
        SizedBox(height: 8),
        _buildPriceRow('Tax', 0),
        Divider(height: 24),
        _buildPriceRow('Total', orderData['total'], isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.blue : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildInfoRow('Name', userData['contact_name'] ?? 'N/A'),
        _buildInfoRow('Email', userData['email'] ?? 'N/A'),
        _buildInfoRow('Phone', userData['phone'] ?? 'N/A'),
        _buildInfoRow('Company', userData['company_name'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildAddressInfo(Map<String, dynamic> address) {
    return Column(
      children: [
        _buildInfoRow('Name', address['name'] ?? 'N/A'),
        _buildInfoRow('Address', address['adress'] ?? 'N/A'),
        _buildInfoRow('City', address['city'] ?? 'N/A'),
        _buildInfoRow('Country', address['country'] ?? 'N/A'),
        _buildInfoRow('ZIP', address['zip'] ?? 'N/A'),
        _buildInfoRow('Phone', address['phone'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildStatusHistory() {
    final history = (orderData['statusHistory'] as List<dynamic>?) ?? [];
    return Column(
      children: history.map((status) {
        final timestamp = status['timestamp'] as Timestamp;
        return ListTile(
          leading: Icon(Icons.circle, size: 12, color: Colors.blue),
          title: Text(status['status']),
          subtitle: Text(_formatDate(timestamp)),
          trailing: Text(status['note'] ?? ''),
        );
      }).toList(),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateOrderStatus(context),
                child: Text('Update Status'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _printInvoice(context),
                child: Text('Print Invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Email Customer'),
              onTap: () {
                Navigator.pop(context);
                _emailCustomer(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_shipping_outlined),
              title: Text('Update Tracking'),
              onTap: () {
                Navigator.pop(context);
                _updateTracking(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh),
              title: Text('Refund Order'),
              onTap: () {
                Navigator.pop(context);
                _showRefundDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete Order'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOrder(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(BuildContext context) async {
    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled'
    ];
    final currentStatus = orderData['status'] as String;

    String? selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: currentStatus,
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedStatus != null && selectedStatus != currentStatus) {
      try {
        await _firestore
            .collection('orders')
            .doc(orderData['order_id'])
            .update({
          'status': selectedStatus,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order status updated successfully')),
          );
        }
      } catch (e) {
        print('Error updating order status: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update order status')),
          );
        }
      }
    }
  }

  Future<void> _updateTracking(BuildContext context) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Tracking Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carrierController,
              decoration: InputDecoration(
                labelText: 'Shipping Carrier',
                hintText: 'e.g., FedEx, UPS, DHL',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (trackingController.text.isNotEmpty) {
                try {
                  await _firestore
                      .collection('orders')
                      .doc(orderData['order_id'])
                      .update({
                    'tracking_info': {
                      'carrier': carrierController.text,
                      'number': trackingController.text,
                      'updated_at': FieldValue.serverTimestamp(),
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tracking information updated')),
                  );
                } catch (e) {
                  print('Error updating tracking info: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to update tracking information')),
                  );
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _emailCustomer(BuildContext context) async {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send an email to ${orderData['user_data']['email']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your message to the customer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement email sending logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Email sent to customer')),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    // Implement invoice printing logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printing invoice...')),
    );
  }

  Future<void> _showRefundDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final total = orderData['total'] as double;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order Total: \$${total.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Refund Amount',
                prefixText: '\$',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason for Refund',
                hintText: 'Enter the reason for the refund',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement refund logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refund processed successfully')),
              );
            },
            child: Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text(
            'Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('orders')
            .doc(orderData['order_id'])
            .delete();

        Navigator.pop(context); // Return to orders list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order deleted successfully')),
        );
      } catch (e) {
        print('Error deleting order: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete order')),
        );
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
