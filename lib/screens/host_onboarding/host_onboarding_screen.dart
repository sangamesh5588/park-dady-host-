import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostOnboardingScreen extends StatefulWidget {
  const HostOnboardingScreen({super.key});

  @override
  State<HostOnboardingScreen> createState() => _HostOnboardingScreenState();
}

class _HostOnboardingScreenState extends State<HostOnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _hasExistingProfile = false;
  String? _existingProfileStatus;
  bool _isCheckingProfile = true; // Block form rendering during profile check

  // Form Data
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _udyamController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();

  // Form Data - Values
  double? _latitude;
  double? _longitude;
  String _businessType = 'Individual';

  // Images
  XFile? _identityProof;
  XFile? _profilePhoto;
  XFile? _businessAddressProof;
  XFile? _udyamCertificate;
  XFile? _cancelledCheque;

  final List<String> _steps = [
    'Personal Details',
    'Identity Verification',
    'Business Details',
    'Bank & Manager Details',
  ];

  // Validation patterns
  final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _gstRegex = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$');

  // Form validation functions
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit phone number starting with 6-9';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  String? _validateGST(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!_gstRegex.hasMatch(value.trim().toUpperCase())) {
        return 'Enter a valid GST number';
      }
    }
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }
    if (!_ifscRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid IFSC code (e.g., ABCD0123456)';
    }
    return null;
  }

  String? _validateAccountHolder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account holder name is required';
    }
    if (value.trim().length < 2) {
      return 'Account holder name must be at least 2 characters';
    }
    return null;
  }

  String? _validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank name is required';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    if (value.trim().length < 9 || value.trim().length > 18) {
      return 'Account number must be 9-18 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  String? _validateManagerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Manager name is required';
    }
    if (value.trim().length < 2) {
      return 'Manager name must be at least 2 characters';
    }
    return null;
  }

  String? _validateManagerPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Manager phone number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit phone number starting with 6-9';
    }
    return null;
  }

  String? _validateManagerEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!_emailRegex.hasMatch(value.trim())) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }

  String? _validateCompanyName(String? value) {
    if (_businessType == 'Company' && (value == null || value.trim().isEmpty)) {
      return 'Company name is required for company business type';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
    _loadSavedFormData();
    _checkExistingProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if user already has a profile and redirect immediately
    _redirectIfProfileExists();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Set email
        if (user.email != null) {
          _emailController.text = user.email!;
        }

        // Try to get full name from user metadata (OAuth providers)
        final userMetadata = user.userMetadata;
        if (userMetadata != null) {
          final fullName = userMetadata['full_name'] ?? userMetadata['name'];
          if (fullName != null && fullName.toString().isNotEmpty) {
            _fullNameController.text = fullName.toString();
          }
        }

        // If no name from metadata, try to get from user_roles table
        if (_fullNameController.text.isEmpty) {
          try {
            final response = await Supabase.instance.client
                .from('user_roles')
                .select('full_name')
                .eq('user_id', user.id)
                .maybeSingle();

            if (response != null && response['full_name'] != null) {
              _fullNameController.text = response['full_name'].toString();
            }
          } catch (e) {
            // Handle silently
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      // Handle location error
    }
  }

  Future<void> _pickImage(ImageSource source, Function(XFile?) onPicked) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    setState(() {
      onPicked(image);
    });
  }

  void _showImageSourceDialog(Function(XFile?) onPicked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, onPicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, onPicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadFileToSupabase(XFile file, String bucket, String path) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$path/$fileName';

      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );

      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    // Check if user is authenticated
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload files to Supabase
      String? identityProofUrl;
      String? profilePhotoUrl;
      String? businessAddressProofUrl;
      String? udyamCertificateUrl;
      String? cancelledChequeUrl;

      if (_identityProof != null) {
        identityProofUrl = await _uploadFileToSupabase(_identityProof!, 'host_onboarding', 'identity_proofs');
      }
      if (_profilePhoto != null) {
        profilePhotoUrl = await _uploadFileToSupabase(_profilePhoto!, 'host_onboarding', 'profile_photos');
      }
      if (_businessAddressProof != null) {
        businessAddressProofUrl = await _uploadFileToSupabase(_businessAddressProof!, 'host_onboarding', 'business_proofs');
      }
      if (_udyamCertificate != null) {
        udyamCertificateUrl = await _uploadFileToSupabase(_udyamCertificate!, 'host_onboarding', 'udyam_certificates');
      }
      if (_cancelledCheque != null) {
        cancelledChequeUrl = await _uploadFileToSupabase(_cancelledCheque!, 'host_onboarding', 'bank_proofs');
      }

      // Prepare host profile data
      final hostData = {
        'user_id': currentUser.id,
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'identity_proof_url': identityProofUrl,
        'profile_photo_url': profilePhotoUrl,
        'business_type': _businessType,
        'company_name': _businessType == 'Company' ? _companyNameController.text : null,
        'gst_number': _gstController.text,
        'udyam_id': _udyamController.text,
        'business_address_proof_url': businessAddressProofUrl,
        'udyam_certificate_url': udyamCertificateUrl,
        'account_holder_name': _accountHolderController.text,
        'bank_name': _bankNameController.text,
        'account_number': _accountNumberController.text,
        'ifsc_code': _ifscController.text,
        'cancelled_cheque_url': cancelledChequeUrl,
        'manager_name': _managerNameController.text,
        'manager_phone': _managerPhoneController.text,
        'manager_email': _managerEmailController.text,
        'status': 'pending_approval',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save to Supabase
      await Supabase.instance.client.from('host_profiles').insert(hostData);

      // Update user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'host_profile_completed': true},
        ),
      );

      // Clear saved form data after successful submission
      await _clearSavedFormData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to approval waiting screen since profile needs approval
        Navigator.of(context).pushReplacementNamed('/host_approval_waiting');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() async {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      return; // Validation failed, don't proceed
    }

    // Save form data
    await _saveFormData();

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validatePersonalDetailsStep();
      case 1:
        return _validateIdentityVerificationStep();
      case 2:
        return _validateBusinessDetailsStep();
      case 3:
        return _validateBankManagerDetailsStep();
      default:
        return true;
    }
  }

  bool _validatePersonalDetailsStep() {
    // Trigger form validation to show individual field errors under each TextFormField
    final formValid = _formKey.currentState?.validate() ?? false;

    // Check location selection separately (not part of form validation)
    final locationValid = _latitude != null && _longitude != null;

    if (!locationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your location using the button above'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return formValid;
  }

  bool _validateIdentityVerificationStep() {
    final identityProofValid = _identityProof != null;

    if (!identityProofValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your identity proof document'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateBusinessDetailsStep() {
    // Trigger form validation for business details step
    final formValid = _formKey.currentState?.validate() ?? false;

    // Check business type specific validation (company name when business type is Company)
    if (_businessType == 'Company') {
      final companyNameValid = _validateCompanyName(_companyNameController.text) == null;
      if (!companyNameValid) {
        // This will be handled by the form validator on the company name field
        return false;
      }
    }
    return formValid;
  }

  bool _validateBankManagerDetailsStep() {
    // Trigger form validation to show individual field errors under each TextFormField
    final formValid = _formKey.currentState?.validate() ?? false;

    // Check file upload separately (not part of form validation)
    final cancelledChequeValid = _cancelledCheque != null;

    if (!cancelledChequeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your cancelled cheque or bank statement'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return formValid;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking for existing profiles
    if (_isCheckingProfile) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
              SizedBox(height: 16),
              Text(
                'Checking profile status...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Host Profile Setup',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: const Color(0xFFE0E7FF),
                    color: const Color(0xFF6366F1),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _steps[_currentStep],
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100), // Extra padding for navigation buttons
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == _steps.length - 1 ? 'Submit' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalDetailsStep();
      case 1:
        return _buildIdentityVerificationStep();
      case 2:
        return _buildBusinessDetailsStep();
      case 3:
        return _buildBankManagerDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please provide your basic information',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _fullNameController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Full Name *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _validateFullName,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _phoneController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Email Address *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _addressController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Address *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          maxLines: 3,
          validator: _validateAddress,
        ),
        const SizedBox(height: 24),

        const Text(
          'Location Selection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 12),

        // Location selection options - temporarily hidden map selection
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              setState(() => _isLoadingLocation = true);
              try {
                final position = await Geolocator.getCurrentPosition();
                setState(() {
                  _latitude = position.latitude;
                  _longitude = position.longitude;
                  _isLoadingLocation = false;
                });
              } catch (e) {
                setState(() => _isLoadingLocation = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to get current location'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Location display
        if (_latitude != null && _longitude != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Selected',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _latitude = null;
                      _longitude = null;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  color: const Color(0xFF6366F1),
                  tooltip: 'Change location',
                ),
              ],
            ),
          )
        else if (_isLoadingLocation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Getting location...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select your location using one of the options above',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIdentityVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identity Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload required documents for verification',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        _buildFileUploadSection(
          title: 'Identity Proof',
          subtitle: 'Upload Aadhar, PAN, or Govt ID',
          file: _identityProof,
          onTap: () => _showImageSourceDialog((file) => _identityProof = file),
        ),
        const SizedBox(height: 16),

        _buildFileUploadSection(
          title: 'Profile Photo',
          subtitle: 'Upload a clear photo of yourself (optional)',
          file: _profilePhoto,
          onTap: () => _showImageSourceDialog((file) => _profilePhoto = file),
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your business operations',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        DropdownButtonFormField<String>(
          value: _businessType,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Business Type',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: ['Individual', 'Company'].map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _businessType = value!),
        ),
        const SizedBox(height: 16),

        if (_businessType == 'Company')
          TextFormField(
            controller: _companyNameController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Company Name',
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: _validateCompanyName,
          ),
        if (_businessType == 'Company') const SizedBox(height: 16),

        TextFormField(
          controller: _gstController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'GST Number',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _udyamController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Udyam / UI ID',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),

        _buildFileUploadSection(
          title: 'Business Address Proof',
          subtitle: 'Upload electricity bill, rental agreement, etc.',
          file: _businessAddressProof,
          onTap: () => _showImageSourceDialog((file) => _businessAddressProof = file),
        ),
        const SizedBox(height: 16),

        _buildFileUploadSection(
          title: 'Udyam Certificate',
          subtitle: 'Upload Udyam certificate (optional)',
          file: _udyamCertificate,
          onTap: () => _showImageSourceDialog((file) => _udyamCertificate = file),
        ),
      ],
    );
  }

  Widget _buildBankManagerDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank Account Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide your banking information for payouts',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _accountHolderController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Account Holder Name *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _validateAccountHolder,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _bankNameController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Bank Name *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _validateBankName,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _accountNumberController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Account Number *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.number,
          validator: _validateAccountNumber,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _ifscController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'IFSC Code *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _validateIFSC,
        ),
        const SizedBox(height: 16),

        _buildFileUploadSection(
          title: 'Cancelled Cheque / Passbook',
          subtitle: 'Upload bank proof document',
          file: _cancelledCheque,
          onTap: () => _showImageSourceDialog((file) => _cancelledCheque = file),
        ),
        const SizedBox(height: 32),

        Text(
          'Manager / Person In-Charge Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Contact information for your manager',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _managerNameController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Manager Name *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _validateManagerName,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _managerPhoneController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Manager Contact Number *',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.phone,
          validator: _validateManagerPhone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _managerEmailController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Manager Email (optional)',
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildFileUploadSection({
    required String title,
    required String subtitle,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null ? const Color(0xFF6366F1) : Colors.grey[300]!,
                width: file != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: file != null ? const Color(0xFFF0F4FF) : Colors.grey[50],
              boxShadow: file != null ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: file != null ? const Color(0xFF6366F1) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    file != null ? Icons.check_circle : Icons.upload_file,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file != null ? 'File uploaded successfully' : subtitle,
                        style: TextStyle(
                          color: file != null ? const Color(0xFF6366F1) : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: file != null ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Display selected image as thumbnail
        if (file != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Image',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (file.name.isNotEmpty && file.name.length > 30)
                            ? '${file.name.substring(0, 27)}...'
                            : (file.name.isNotEmpty ? file.name : file.path.split('/').last),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    // Clear the file based on which field it is
                    if (file == _identityProof) _identityProof = null;
                    else if (file == _profilePhoto) _profilePhoto = null;
                    else if (file == _businessAddressProof) _businessAddressProof = null;
                    else if (file == _udyamCertificate) _udyamCertificate = null;
                    else if (file == _cancelledCheque) _cancelledCheque = null;
                  }),
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red[400],
                  tooltip: 'Remove image',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _loadSavedFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'host_onboarding_${user.id}';

        // Load saved form data
        _fullNameController.text = prefs.getString('${userKey}_fullName') ?? '';
        _phoneController.text = prefs.getString('${userKey}_phone') ?? '';
        _emailController.text = prefs.getString('${userKey}_email') ?? '';
        _addressController.text = prefs.getString('${userKey}_address') ?? '';
        _businessType = prefs.getString('${userKey}_businessType') ?? 'Individual';
        _companyNameController.text = prefs.getString('${userKey}_companyName') ?? '';
        _gstController.text = prefs.getString('${userKey}_gst') ?? '';
        _udyamController.text = prefs.getString('${userKey}_udyam') ?? '';
        _accountHolderController.text = prefs.getString('${userKey}_accountHolder') ?? '';
        _bankNameController.text = prefs.getString('${userKey}_bankName') ?? '';
        _accountNumberController.text = prefs.getString('${userKey}_accountNumber') ?? '';
        _ifscController.text = prefs.getString('${userKey}_ifsc') ?? '';
        _managerNameController.text = prefs.getString('${userKey}_managerName') ?? '';
        _managerPhoneController.text = prefs.getString('${userKey}_managerPhone') ?? '';
        _managerEmailController.text = prefs.getString('${userKey}_managerEmail') ?? '';

        // Load coordinates
        final lat = prefs.getDouble('${userKey}_latitude');
        final lng = prefs.getDouble('${userKey}_longitude');
        if (lat != null && lng != null) {
          _latitude = lat;
          _longitude = lng;
        }

        // Load current step
        _currentStep = prefs.getInt('${userKey}_currentStep') ?? 0;

        setState(() {});
      }
    } catch (e) {
      // Handle silently - use defaults
    }
  }

  Future<void> _saveFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'host_onboarding_${user.id}';

        // Save form data
        await prefs.setString('${userKey}_fullName', _fullNameController.text);
        await prefs.setString('${userKey}_phone', _phoneController.text);
        await prefs.setString('${userKey}_email', _emailController.text);
        await prefs.setString('${userKey}_address', _addressController.text);
        await prefs.setString('${userKey}_businessType', _businessType);
        await prefs.setString('${userKey}_companyName', _companyNameController.text);
        await prefs.setString('${userKey}_gst', _gstController.text);
        await prefs.setString('${userKey}_udyam', _udyamController.text);
        await prefs.setString('${userKey}_accountHolder', _accountHolderController.text);
        await prefs.setString('${userKey}_bankName', _bankNameController.text);
        await prefs.setString('${userKey}_accountNumber', _accountNumberController.text);
        await prefs.setString('${userKey}_ifsc', _ifscController.text);
        await prefs.setString('${userKey}_managerName', _managerNameController.text);
        await prefs.setString('${userKey}_managerPhone', _managerPhoneController.text);
        await prefs.setString('${userKey}_managerEmail', _managerEmailController.text);

        // Save coordinates
        if (_latitude != null) await prefs.setDouble('${userKey}_latitude', _latitude!);
        if (_longitude != null) await prefs.setDouble('${userKey}_longitude', _longitude!);

        // Save current step
        await prefs.setInt('${userKey}_currentStep', _currentStep);
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _redirectIfProfileExists() async {
    try {
      print('🔍 Checking for existing host profile...');
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user found');
        setState(() => _isCheckingProfile = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        final status = response['status'];
        print('📋 Found existing profile with status: $status');

        if (status == 'approved') {
          // Profile approved - go to main app immediately
          print('✅ Profile approved - redirecting to main app');
          setState(() => _isCheckingProfile = false);
          await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for UI
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/main');
          }
          return;
        } else if (status == 'pending_approval') {
          // Profile pending - go to approval waiting immediately
          print('⏳ Profile pending approval - redirecting to approval waiting');
          setState(() => _isCheckingProfile = false);
          await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for UI
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/host_approval_waiting');
          }
          return;
        } else if (status == 'rejected') {
          // Profile rejected - allow re-submission, continue to form
          print('❌ Profile rejected - allowing re-submission');
          _hasExistingProfile = true;
          _existingProfileStatus = status;
          setState(() => _isCheckingProfile = false);
          return;
        }
      } else {
        print('ℹ️ No existing profile found - showing form');
      }
    } catch (e) {
      print('❌ Error checking profile status: $e');
      // On error, allow form submission
    }

    // Complete profile checking
    if (mounted) {
      setState(() => _isCheckingProfile = false);
    }
  }

  Future<void> _checkExistingProfile() async {
    // This method is now redundant since _redirectIfProfileExists handles everything
    // Keep for backward compatibility but delegate to the main method
    await _redirectIfProfileExists();
  }

  Future<void> _clearSavedFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'host_onboarding_${user.id}';

        // Remove all saved form data
        await prefs.remove('${userKey}_fullName');
        await prefs.remove('${userKey}_phone');
        await prefs.remove('${userKey}_email');
        await prefs.remove('${userKey}_address');
        await prefs.remove('${userKey}_businessType');
        await prefs.remove('${userKey}_companyName');
        await prefs.remove('${userKey}_gst');
        await prefs.remove('${userKey}_udyam');
        await prefs.remove('${userKey}_accountHolder');
        await prefs.remove('${userKey}_bankName');
        await prefs.remove('${userKey}_accountNumber');
        await prefs.remove('${userKey}_ifsc');
        await prefs.remove('${userKey}_managerName');
        await prefs.remove('${userKey}_managerPhone');
        await prefs.remove('${userKey}_managerEmail');
        await prefs.remove('${userKey}_latitude');
        await prefs.remove('${userKey}_longitude');
        await prefs.remove('${userKey}_currentStep');
      }
    } catch (e) {
      // Handle silently
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _gstController.dispose();
    _udyamController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _managerEmailController.dispose();
    super.dispose();
  }
}
