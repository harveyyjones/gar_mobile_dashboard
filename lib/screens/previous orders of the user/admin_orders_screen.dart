import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/business%20logic/models/admin_order_model.dart';
import 'package:shop_app/business%20logic/admin_orders_service.dart';
import 'package:shop_app/screens/previous%20orders%20of%20the%20user/order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  @override
  _AdminOrdersScreenState createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminOrderService _orderService = AdminOrderService();
  String _selectedStatus = 'all';
  String _selectedTimeRange = 'today';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  OrderStatistics? _orderStats;

  @override
  void initState() {
    super.initState();
    _loadOrderStatistics();
  }

  Future<void> _loadOrderStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _orderService.getOrderStatistics();
      setState(() => _orderStats = stats);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    return _orderService.getOrders(
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
      timeRange: _selectedTimeRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Management', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrderStatistics,
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsSection(),
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error details: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading orders'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data?.docs ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(orders[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_orderStats == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  _orderStats!.total.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  '\ PLN ${_orderStats!.totalRevenue.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  _orderStats!.getStatusCount('pending').toString(),
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Processing',
                  _orderStats!.getStatusCount('processing').toString(),
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Shipped',
                  _orderStats!.getStatusCount('shipped').toString(),
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatusChip('All', 'all'),
          _buildStatusChip('Pending', 'pending'),
          _buildStatusChip('Processing', 'processing'),
          _buildStatusChip('Shipped', 'shipped'),
          _buildStatusChip('Delivered', 'delivered'),
          _buildStatusChip('Cancelled', 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() => _selectedStatus = selected ? status : 'all');
        },
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final status = data['status'] as String? ?? 'pending';
    final total = data['total'] as double? ?? 0.0;
    final currency = data['items']?[0]['currency'] as String? ?? 'USD';
    final orderDate =
        (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminOrderDetailScreen(orderData: data),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Ordered on ${_formatDate(orderDate)}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Divider(height: 24),
              Text(
                '${items.length} items • $currency${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateOrderStatus(order.id, status),
                    child: Text('Update Status'),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showOrderActions(order.id),
                    child: Text('More Actions'),
                  ),
                ],
              ),
            ],
          ),
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
            status[0].toUpperCase() + status.substring(1).toLowerCase(),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: InputDecoration(labelText: 'Time Range'),
              items: [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
              ],
              onChanged: (value) {
                if (value == 'custom') {
                  _showDateRangePicker();
                } else {
                  setState(() => _selectedTimeRange = value!);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedTimeRange = 'custom';
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: currentStatus,
              decoration: InputDecoration(labelText: 'Status'),
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await _orderService.updateOrderStatus(
                      context,
                      {
                        'order_id': orderId,
                        'new_status': value,
                      },
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error updating order status: $e');
                  }
                }
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
  }

  void _showOrderActions(String orderId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.print),
              title: Text('Print Invoice'),
              onTap: () => _handlePrintInvoice(orderId),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete Order'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _handleDeleteOrder(orderId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrintInvoice(String orderId) async {
    // Implement invoice printing logic
    Navigator.pop(context);
  }

  Future<void> _handleDeleteOrder(String orderId) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _orderService.deleteOrder(orderId);
        _showSnackBar('Order deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete order', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
