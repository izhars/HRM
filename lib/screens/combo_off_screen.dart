import 'package:flutter/material.dart';
import '../component/combo_off_card.dart';
import '../models/ComboOff.dart';
import '../services/combo_services.dart';

class ComboOffScreen extends StatefulWidget {
  const ComboOffScreen({Key? key}) : super(key: key);

  @override
  State<ComboOffScreen> createState() => _ComboOffScreenState();
}

class _ComboOffScreenState extends State<ComboOffScreen> {
  final ComboApi _comboApi = ComboApi();
  List<ComboOff> comboOffs = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _reasonController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchComboOffs();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> fetchComboOffs() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final combos = await _comboApi.getMyComboOffs();
      if (mounted) {
        setState(() {
          comboOffs = combos;
        });
      }
    } catch (e) {
      _handleApiError(e, 'Failed to load combo offs');
      debugPrint('Fetch combo offs error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showApplyDialog() {
    _reasonController.clear();
    selectedDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Apply for Combo Off",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Reason for Combo Off",
                      hintText: "Enter reason...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        selectableDayPredicate: (DateTime date) {
                          // Allow all days for now
                          // Check for existing applications
                          final hasApplication = comboOffs.any((combo) {
                            return combo.date.year == date.year &&
                                combo.date.month == date.month &&
                                combo.date.day == date.day &&
                                !combo.isRejected;
                          });
                          return !hasApplication;
                        },
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedDate == null
                                      ? "Select Work Date"
                                      : "Work Date: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                                if (selectedDate == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Select your preferred work date",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleSubmit(sheetContext),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Application",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmit(BuildContext sheetContext) async {
    // Validate inputs
    if (_reasonController.text.isEmpty) {
      _showSnackBar(sheetContext, 'Please enter a reason', Colors.orange);
      return;
    }

    if (_reasonController.text.length < 10) {
      _showSnackBar(sheetContext, 'Please provide a more detailed reason (minimum 10 characters)', Colors.orange);
      return;
    }

    if (selectedDate == null) {
      _showSnackBar(sheetContext, 'Please select a date', Colors.orange);
      return;
    }

    // Check if combo off already exists for this date
    final isDuplicate = comboOffs.any((combo) {
      return combo.date.year == selectedDate!.year &&
          combo.date.month == selectedDate!.month &&
          combo.date.day == selectedDate!.day &&
          !combo.isRejected;
    });

    if (isDuplicate) {
      _showSnackBar(
        sheetContext,
        'You have already applied for Combo Off on ${selectedDate!.toLocal().toString().split(' ')[0]}',
        Colors.orange,
      );
      return;
    }

    // Close the bottom sheet first
    Navigator.of(sheetContext).pop();

    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _LoadingDialog(),
    );

    try {
      await _comboApi.applyComboOff(
        _reasonController.text,
        selectedDate!,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      _showSnackBar(context, 'Combo Off applied successfully!', Colors.green);

      // Refresh the list
      await fetchComboOffs();

    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show the API error message directly
      String errorMessage = 'Something went wrong!';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      _showSnackBar(context, errorMessage, Colors.red);
    }
  }

  Future<void> _handleDeleteComboOff(String comboId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to delete this combo off request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _LoadingDialog(),
    );

    try {
      final success = await _comboApi.deleteComboOff(comboId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      if (success) {
        _showSnackBar(context, 'Request deleted successfully', Colors.green);
        await fetchComboOffs();
      } else {
        _showSnackBar(context, 'Failed to delete request', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      _handleApiError(e, 'Failed to delete combo off');
    }
  }

  void _handleApiError(dynamic error, String defaultMessage) {
    String errorMessage = defaultMessage;

    // If the error comes from the API and has a message
    if (error is Map<String, dynamic> && error.containsKey('message')) {
      errorMessage = error['message'];
    } else if (error.toString().contains('Exception: ')) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } else {
      // fallback to whatever error.toString() gives
      errorMessage = error.toString();
    }

    if (mounted) {
      _showSnackBar(context, errorMessage, Colors.red);
      setState(() {
        this.errorMessage = errorMessage;
      });
    }
  }



  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  int get _pendingCount => comboOffs.where((c) => c.status == 'pending').length;
  int get _approvedCount => comboOffs.where((c) => c.status == 'approved').length;
  int get _rejectedCount => comboOffs.where((c) => c.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Combo Offs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchComboOffs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Apply'),
        tooltip: 'Apply for Combo Off',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null && comboOffs.isEmpty
          ? _buildErrorWidget()
          : Column(
        children: [
          if (comboOffs.isNotEmpty) ...[
            _buildStatsCard(),
          ],
          Expanded(
            child: comboOffs.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
              onRefresh: fetchComboOffs,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 80,
                ),
                itemCount: comboOffs.length,
                itemBuilder: (context, index) {
                  final combo = comboOffs[index];
                  return ComboOffCard(
                    combo: combo,
                    onDelete: () => _handleDeleteComboOff(combo.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Unable to Load Data",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: fetchComboOffs,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No Combo Offs Applied",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button below to apply",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Pending',
            _pendingCount,
            Colors.orange,
            Icons.hourglass_empty,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade300,
          ),
          _buildStatCard(
            'Approved',
            _approvedCount,
            Colors.green,
            Icons.check_circle,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade300,
          ),
          _buildStatCard(
            'Rejected',
            _rejectedCount,
            Colors.red,
            Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}