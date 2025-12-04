import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/avatar_api.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  File? _avatar;
  User? _user;
  bool _isLoading = true;
  bool _isUploading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Modern color palette
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accentColor = Color(0xFF10B981);
  static const Color dividerColor = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      // Load avatar and user data
      final results = await Future.wait([
        AvatarService.getAvatar(),
        _authService.fetchMe(),
      ]);

      setState(() {
        _avatar = results[0] as File?;
        _user = results[1] as User?;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load profile. Please try again.');
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    // Check file size before uploading (5MB limit)
    final fileSize = await imageFile.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      _showErrorSnackBar('Image size too large. Please select image under 5MB');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await _authService.uploadProfilePicture(imageFile);

      if (result != null && result['success'] == true) {
        setState(() {
          _avatar = imageFile;
          if (result['user'] != null) {
            _user = User.fromJson(result['user']);
          }
        });

        _showSuccessSnackBar('Profile picture updated successfully!');
      } else {
        throw Exception(result?['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Upload error: $e');

      if (e.toString().contains('Invalid file type') ||
          e.toString().contains('Only image files')) {
        _showErrorSnackBar('Please select a valid image file (JPEG, PNG, GIF)');
      } else if (e.toString().contains('file size')) {
        _showErrorSnackBar('Image size too large. Please select image under 5MB');
      } else {
        _showErrorSnackBar('Failed to upload profile picture. Please try again.');
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      _showErrorSnackBar('Failed to take photo');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Update Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Supported formats: JPEG, PNG, GIF\nMax size: 5MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildBottomSheetOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _buildBottomSheetOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use your camera',
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dividerColor,
                    foregroundColor: textPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    try {
      return DateFormat('dd MMM, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String formatCurrency(double? amount, String? currency) {
    if (amount == null) return 'Not specified';
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${NumberFormat('#,##0.00').format(amount)}';
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_user == null) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _buildProfileCards(),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isUploading) _buildUploadOverlay(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadProfile();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, primaryLight],
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutBack,
            )),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildProfileAvatar(),
                const SizedBox(height: 16),
                Text(
                  _user!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.designation ?? 'Employee',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _user!.department?.name ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusChip(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Hero(
        tag: 'profile_avatar',
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? Text(
                  _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                )
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Uploading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    // First, check if profilePicture from API is not empty
    if (_user!.profilePicture.isNotEmpty) {
      return NetworkImage(_user!.profilePicture);
    }
    // If profilePicture is empty, use the local avatar file
    else if (_avatar != null) {
      return FileImage(_avatar!);
    }
    // If neither is available, return null to show the initial
    return null;
  }

  Widget _buildStatusChip() {
    final isActive = _user!.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? accentColor : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _user!.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileCards() {
    return [
      _buildPersonalInfoCard(),
      const SizedBox(height: 16),
      if (_user!.address != null) ...[
        _buildAddressCard(),
        const SizedBox(height: 16),
      ],
      _buildEmploymentCard(),
      const SizedBox(height: 16),
      if (_user!.salary != null) ...[
        _buildSalaryCard(),
        const SizedBox(height: 16),
      ],
      if (_user!.bankDetails != null) ...[
        _buildBankDetailsCard(),
        const SizedBox(height: 16),
      ],
      if (_user!.leaveBalance != null) ...[
        _buildLeaveBalanceCard(),
        const SizedBox(height: 16),
      ],
      if (_user!.emergencyContact != null) ...[
        _buildEmergencyContactCard(),
        const SizedBox(height: 16),
      ],
      if (_user!.spouseDetails != null) ...[
        _buildSpouseDetailsCard(),
        const SizedBox(height: 16),
      ],
      _buildAccountInfoCard(),
      const SizedBox(height: 32),
    ];
  }
  Widget _buildPersonalInfoCard() {
    return _buildCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Employee ID', _user!.employeeId, Icons.badge_outlined),
        _buildInfoRow('Email', _user!.email, Icons.email_outlined),
        _buildInfoRow('Phone', _user!.phone, Icons.phone_outlined),
        _buildInfoRow('Gender', _user!.gender?.toUpperCase(), Icons.person_outline),
        _buildInfoRow('Date of Birth', formatDate(_user!.dateOfBirth), Icons.cake_outlined),
        _buildInfoRow('Marital Status', _user!.maritalStatus?.toUpperCase(), Icons.favorite_outline),
      ],
    );
  }

  Widget _buildAddressCard() {
    return _buildCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: [
        _buildInfoRow('City', _user!.address?.city, Icons.location_city_outlined),
        _buildInfoRow('State', _user!.address?.state, Icons.map_outlined),
        _buildInfoRow('Country', _user!.address?.country, Icons.public_outlined),
      ],
    );
  }

  Widget _buildEmploymentCard() {
    return _buildCard(
      title: 'Employment Details',
      icon: Icons.work_outline,
      children: [
        _buildInfoRow('Date of Joining', formatDate(_user!.dateOfJoining), Icons.today_outlined),
        _buildInfoRow('Employment Type', _user!.employmentType?.toUpperCase(), Icons.badge_outlined),
        _buildInfoRow('PF Number', _user!.pfNumber, Icons.account_balance_outlined),
        _buildInfoRow('UAN Number', _user!.uanNumber, Icons.numbers_outlined),
        _buildInfoRow('PAN Number', _user!.panNumber, Icons.credit_card_outlined),
        if (_user!.lastLogin != null)
          _buildInfoRow('Last Login', formatDate(_user!.lastLogin), Icons.login_outlined),
      ],
    );
  }

  Widget _buildSalaryCard() {
    return _buildCard(
      title: 'Salary Information',
      icon: Icons.payments_outlined,
      children: [
        _buildInfoRow('Basic', formatCurrency(_user!.salary?.basic, _user!.salary?.currency), Icons.money_outlined),
        _buildInfoRow('HRA', formatCurrency(_user!.salary?.hra, _user!.salary?.currency), Icons.home_outlined),
        _buildInfoRow('Transport', formatCurrency(_user!.salary?.transport, _user!.salary?.currency), Icons.directions_car_outlined),
        _buildInfoRow('Allowances', formatCurrency(_user!.salary?.allowances, _user!.salary?.currency), Icons.add_circle_outline),
        _buildInfoRow('Deductions', formatCurrency(_user!.salary?.deductions, _user!.salary?.currency), Icons.remove_circle_outline),
        const Divider(color: dividerColor),
        _buildInfoRow('Net Salary', formatCurrency(_user!.salary?.netSalary, _user!.salary?.currency), Icons.account_balance_wallet_outlined, isHighlighted: true),
        _buildInfoRow('Pay Frequency', _user!.salary?.payFrequency?.toUpperCase(), Icons.schedule_outlined),
      ],
    );
  }

  Widget _buildBankDetailsCard() {
    return _buildCard(
      title: 'Bank Details',
      icon: Icons.account_balance_outlined,
      children: [
        _buildInfoRow('Bank Name', _user!.bankDetails?.bankName, Icons.account_balance),
        _buildInfoRow('Account Number', _user!.bankDetails?.accountNumber, Icons.credit_card_outlined),
        _buildInfoRow('IFSC Code', _user!.bankDetails?.ifscCode, Icons.code_outlined),
      ],
    );
  }

  Widget _buildLeaveBalanceCard() {
    return _buildCard(
      title: 'Leave Balance',
      icon: Icons.event_available_outlined,
      children: [
        _buildInfoRow('Casual Leave', '${_user!.leaveBalance?.casual ?? 0} days', Icons.beach_access_outlined),
        _buildInfoRow('Sick Leave', '${_user!.leaveBalance?.sick ?? 0} days', Icons.local_hospital_outlined),
        _buildInfoRow('Earned Leave', '${_user!.leaveBalance?.earned ?? 0} days', Icons.star_outline),
        _buildInfoRow('Unpaid Leave', '${_user!.leaveBalance?.unpaid ?? 0} days', Icons.money_off_outlined),
      ],
    );
  }

  Widget _buildEmergencyContactCard() {
    return _buildCard(
      title: 'Emergency Contact',
      icon: Icons.emergency_outlined,
      children: [
        _buildInfoRow('Name', _user!.emergencyContact?.name, Icons.person_outline),
        _buildInfoRow('Phone', _user!.emergencyContact?.phone, Icons.phone_outlined),
      ],
    );
  }

  Widget _buildSpouseDetailsCard() {
    return _buildCard(
      title: 'Spouse Details',
      icon: Icons.people_outline,
      children: [
        _buildInfoRow('Is Working', _user!.spouseDetails?.isWorking == true ? 'Yes' : 'No', Icons.work_outline),
      ],
    );
  }

  Widget _buildAccountInfoCard() {
    return _buildCard(
      title: 'Account Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Created', formatDate(_user!.createdAt), Icons.calendar_today_outlined),
        _buildInfoRow('Updated', formatDate(_user!.updatedAt), Icons.update_outlined),
        _buildInfoRow('Verified', _user!.isVerified ? 'Yes' : 'No', _user!.isVerified ? Icons.verified_outlined : Icons.warning_outlined),
        if (_user!.createdBy != null)
          _buildInfoRow('Created By', _user!.createdBy?.fullName, Icons.person_add_outlined),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, IconData icon, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textSecondary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isHighlighted ? primaryColor : textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? primaryColor : textPrimary,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _authService.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (Route<dynamic> route) => false,
      );
    }
  }
}