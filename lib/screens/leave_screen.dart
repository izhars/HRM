// lib/screens/leaves_screen.dart
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/leave.dart';
import '../services/leave_api.dart';

class LeavesScreen extends StatefulWidget {
  @override
  _LeavesScreenState createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with SingleTickerProviderStateMixin {
  final LeavesService _leaveService = LeavesService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late TabController _tabController;
  int _selectedTab = 0;
  String? _userRole;
  List<Leave> _leaves = [];
  LeaveBalance? _leaveBalance;
  bool _isLoading = true;
  bool _isBalanceLoading = true;
  bool _isLeavesLoading = false;
  final List<String> _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
        _fetchLeavesWithStatus(
            _tabController.index == 0 ? null : _tabs[_tabController.index].toLowerCase()
        );
      }
    });
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData != null) {
      final userMap = jsonDecode(userData);
      setState(() {
        _userRole = userMap['role'] ?? 'Role not found';
        _isLoading = false;
        _fetchData();
      });
    } else {
      setState(() {
        _userRole = 'No user data found';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchLeaves(),
      if (_userRole == 'employee') _fetchLeaveBalance(),
    ]);
  }

  Future<void> _cancelLeave(Leave leave) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Leave'),
        content: Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _leaveService.cancelLeave(leave.id);
        _showSnackBar('Leave cancelled successfully');
        _fetchData();
      } catch (e) {
        _showSnackBar('Failed to cancel leave: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLeavesLoading = true); // Changed from _isLoading
    try {
      List<dynamic> leavesData;
      if (_userRole == 'employee') {
        leavesData = await _leaveService.getMyLeaves();
      } else {
        leavesData = await _leaveService.getPendingLeaves();
      }
      setState(() {
        _leaves = leavesData.map((json) => Leave.fromJson(json)).toList();
      });
    } catch (e) {
      _showSnackBar('Failed to load leaves: $e', isError: true);
    } finally {
      setState(() => _isLeavesLoading = false); // Changed from _isLoading
    }
  }


  Future<void> _fetchLeaveBalance() async {
    if (_userRole != 'employee') return;
    setState(() => _isBalanceLoading = true);
    try {
      final data = await _leaveService.getLeaveBalance();
      setState(() => _leaveBalance = LeaveBalance.fromJson(data));
    } catch (e) {
      print('Balance error: $e');
    } finally {
      setState(() => _isBalanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_userRole == 'employee') ...[
            SliverToBoxAdapter(child: _buildLeaveBalanceCard()),
            SliverToBoxAdapter(child: _buildEmployeeTabs()),
          ] else
            SliverToBoxAdapter(child: _buildManagerHeader()),
          _buildLeavesList(),
        ],
      ),
      floatingActionButton: _userRole == 'employee'
          ? FloatingActionButton.extended(
        onPressed: _openApplyLeaveSheet,
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white, // <-- makes text & icon white
        icon: Icon(Icons.add),
        label: Text('Apply Leave'),
      )
          : null,
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: _isBalanceLoading
          ? _buildBalanceShimmer()
          : _leaveBalance == null
          ? SizedBox.shrink()
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white70, size: 24),
                SizedBox(width: 8),
                Text('Leave Balance', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceItem('Casual', _leaveBalance!.casual),
                _buildBalanceItem('Sick', _leaveBalance!.sick),
                _buildBalanceItem('Earned', _leaveBalance!.earned),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBalanceShimmer() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(height: 20, color: Colors.white24),
          SizedBox(height: 16),
          Container(height: 40, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final title = _userRole == 'employee' ? 'My Leaves' : 'Team Leaves';
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.refresh), onPressed: _fetchData),
      ],
    );
  }

  Widget _buildManagerHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(Icons.supervisor_account, color: Color(0xFF2E7D32)),
          SizedBox(width: 12),
          Text(
            'Pending Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs
            .map((t) => Tab(
          child: Text(t, style: TextStyle(fontWeight: FontWeight.w600)),
        ))
            .toList(),
        indicatorColor: Color(0xFF2E7D32),
        labelColor: Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey[600],
      ),
    );
  }

  Future<void> _fetchLeavesWithStatus(String? status) async {
    setState(() => _isLeavesLoading = true); // Changed from _isLoading
    try {
      final data = await _leaveService.getMyLeaves(status: status);
      setState(() => _leaves = data.map((j) => Leave.fromJson(j)).toList());
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isLeavesLoading = false); // Changed from _isLoading
    }
  }

  Widget _buildLeavesList() {
    if (_isLeavesLoading) { // Changed from _isLoading
      return SliverFillRemaining(child: _buildShimmerList());
    }
    if (_leaves.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) => _buildLeaveCard(_leaves[i]),
          childCount: _leaves.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No ${_tabs[_selectedTab].toLowerCase()} leaves',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your leave requests will appear here',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 90,
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildLeaveCard(Leave leave) {
    final isManager = _userRole != 'employee';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLeaveDetails(leave),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(leave.status).withOpacity(0.1),
                  child: Icon(_getStatusIcon(leave.status), color: _getStatusColor(leave.status)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isManager ? leave.employeeName : leave.displayLeaveType,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isManager) ...[
                        SizedBox(height: 4),
                        Text(leave.displayLeaveType, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                      SizedBox(height: 4),
                      Text(leave.formattedDateRange, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                if (isManager && leave.status == 'pending') ...[
                  _buildActionButton('Approve', Colors.green, () => _approveLeave(leave.id)),
                  SizedBox(width: 8),
                  _buildActionButton('Reject', Colors.red, () => _rejectLeave(leave.id)),
                ] else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(leave.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      leave.status.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(leave.status), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'cancelled': return Icons.block;
      default: return Icons.hourglass_bottom;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Widget _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'casual':
        return Icon(Icons.beach_access, color: Colors.orange, size: 20);
      case 'sick':
        return Icon(Icons.local_hospital, color: Colors.red, size: 20);
      case 'earned':
        return Icon(Icons.card_giftcard, color: Colors.green, size: 20);
      case 'combo':
        return Icon(Icons.all_inclusive, color: Colors.purple, size: 20);
      case 'unpaid':
        return Icon(Icons.money_off, color: Colors.grey, size: 20);
      case 'maternity':
        return Icon(Icons.child_friendly, color: Colors.pink, size: 20);
      case 'paternity':
        return Icon(Icons.family_restroom, color: Colors.blue, size: 20);
      default:
        return Icon(Icons.category, color: Colors.grey, size: 20);
    }
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'casual':
        return Colors.orange[700]!;
      case 'sick':
        return Colors.red[700]!;
      case 'earned':
        return Colors.green[700]!;
      case 'combo':
        return Colors.purple[700]!;
      case 'unpaid':
        return Colors.grey[700]!;
      case 'maternity':
        return Colors.pink[700]!;
      case 'paternity':
        return Colors.blue[700]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showLeaveDetails(Leave leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(leave.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getStatusIcon(leave.status), color: _getStatusColor(leave.status), size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(leave.displayLeaveType, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(leave.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  leave.status.toUpperCase(),
                                  style: TextStyle(color: _getStatusColor(leave.status), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildDetailRow(Icons.calendar_today, 'Duration', leave.formattedDateRange),
                    _buildDetailRow(Icons.access_time, 'Total Days', leave.durationDisplay),
                    _buildDetailRow(Icons.event, 'Applied On', _formatDate(leave.appliedOn)),
                    if (leave.reason.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text('Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Text(leave.reason, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
                      ),
                    ],
                    if (leave.status == 'rejected' && leave.rejectionReason != null) ...[
                      SizedBox(height: 16),
                      Text('Rejection Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red[700])),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                        child: Text(leave.rejectionReason!, style: TextStyle(fontSize: 14, color: Colors.red[900], height: 1.5)),
                      ),
                    ],
                    if (leave.status == 'pending' || leave.status == 'approved') ...[
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _cancelLeave(leave),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.cancel),
                          label: Text('Cancel Leave'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  // Replace your entire _openApplyLeaveSheet() method with this fixed version:

  void _openApplyLeaveSheet() {
    final _formKey = GlobalKey<FormState>();
    String? _leaveType; // This is correctly defined here
    DateTime? _startDate;
    DateTime? _endDate;
    String _leaveDuration = 'full';
    String? _halfDayType;
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(24),
                      children: [
                        Text('Apply for Leave', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 24),

                        // Leave Type Dropdown - FIXED VERSION
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              value: _leaveType, // NOW IT WILL WORK
                              hint: Row(
                                children: [
                                  Icon(Icons.category, size: 20, color: Colors.grey[600]),
                                  SizedBox(width: 12),
                                  Text(
                                    'Select Leave Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              items: ['casual', 'sick', 'earned', 'combo', 'unpaid', 'maternity', 'paternity']
                                  .map((type) => DropdownMenuItem(
                                value: type,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getLeaveTypeColor(type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        type[0].toUpperCase() + type.substring(1),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                                  .toList(),
                              onChanged: (val) => setModalState(() => _leaveType = val),
                              buttonStyleData: ButtonStyleData(
                                height: 50,
                                padding: EdgeInsets.only(left: 16, right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                              ),
                              iconStyleData: IconStyleData(
                                icon: Icon(Icons.arrow_drop_down),
                                iconSize: 28,
                                iconEnabledColor: Colors.grey[600],
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Leave Duration Toggle
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Leave Duration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text('Full Day', style: TextStyle(fontSize: 14)),
                                      value: 'full',
                                      groupValue: _leaveDuration,
                                      onChanged: (val) {
                                        setModalState(() {
                                          _leaveDuration = val!;
                                          _halfDayType = null;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text('Half Day', style: TextStyle(fontSize: 14)),
                                      value: 'half',
                                      groupValue: _leaveDuration,
                                      onChanged: (val) {
                                        setModalState(() => _leaveDuration = val!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Half Day Type
                        if (_leaveDuration == 'half') ...[
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Half Day Type',
                              prefixIcon: Icon(Icons.schedule),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: [
                              DropdownMenuItem(value: 'first_half', child: Text('First Half (Morning)')),
                              DropdownMenuItem(value: 'second_half', child: Text('Second Half (Afternoon)')),
                            ],
                            onChanged: (val) => setModalState(() => _halfDayType = val),
                            validator: (val) => _leaveDuration == 'half' && val == null ? 'Please select half day type' : null,
                          ),
                        ],

                        SizedBox(height: 16),

                        // Start Date
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _startDate = picked;
                                if (_leaveDuration == 'half') {
                                  _endDate = picked;
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            child: Text(
                              _startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select start date',
                              style: TextStyle(color: _startDate != null ? Colors.black87 : Colors.grey[600]),
                            ),
                          ),
                        ),

                        // End Date
                        if (_leaveDuration == 'full') ...[
                          SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365)),
                              );
                              if (picked != null) setModalState(() => _endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.event),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              child: Text(
                                _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select end date',
                                style: TextStyle(color: _endDate != null ? Colors.black87 : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 16),

                        // Reason
                        TextFormField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (val) => val!.isEmpty ? 'Please enter reason' : null,
                        ),

                        SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Validate leave type
                                if (_leaveType == null) {
                                  _showSnackBar('Please select leave type', isError: true);
                                  return;
                                }

                                if (_startDate == null) {
                                  _showSnackBar('Please select start date', isError: true);
                                  return;
                                }

                                final effectiveEndDate = _leaveDuration == 'half' ? _startDate : _endDate;

                                if (effectiveEndDate == null) {
                                  _showSnackBar('Please select end date', isError: true);
                                  return;
                                }

                                Navigator.pop(context);

                                try {
                                  final leaveData = {
                                    "leaveType": _leaveType,
                                    "startDate": _startDate!.toIso8601String(),
                                    "endDate": effectiveEndDate!.toIso8601String(),
                                    "reason": reasonController.text,
                                    "leaveDuration": _leaveDuration,
                                  };

                                  if (_leaveDuration == 'half' && _halfDayType != null) {
                                    leaveData["halfDayType"] = _halfDayType!;
                                  }

                                  await _leaveService.applyLeave(leaveData);
                                  _showSnackBar('Leave applied successfully!');
                                  _fetchData();
                                } catch (e) {
                                  _showSnackBar('Failed to apply leave: ${e.toString()}', isError: true);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.send),
                            label: Text('Submit Leave Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveLeave(String id) async {
    try {
      await _leaveService.approveLeave(id);
      _showSnackBar('Leave approved');
      _fetchData();
    } catch (e) {
      _showSnackBar('Failed: $e', isError: true);
    }
  }

  Future<void> _rejectLeave(String id) async {
    final reason = await _showRejectionDialog();
    if (reason == null) return;
    try {
      await _leaveService.rejectLeave(id, reason);
      _showSnackBar('Leave rejected');
      _fetchData();
    } catch (e) {
      _showSnackBar('Failed: $e', isError: true);
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Leave'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}