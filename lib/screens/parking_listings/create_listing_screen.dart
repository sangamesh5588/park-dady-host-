import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import step widgets
import 'parking_details_step.dart';
import 'slot_capacity_step.dart';
import 'operational_hours_step.dart';
import 'amenities_photos_step.dart';
import 'pricing_step.dart';
import 'additional_details_step.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _parkingNameController = TextEditingController();
  final _parkingAddressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _carSlotsController = TextEditingController();
  final _bikeSlotsController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _hourlyCarRateController = TextEditingController();
  final _hourlyBikeRateController = TextEditingController();
  final _dailyCarRateController = TextEditingController();
  final _dailyBikeRateController = TextEditingController();
  final _hourlyCarDiscountController = TextEditingController();
  final _hourlyBikeDiscountController = TextEditingController();
  final _dailyCarDiscountController = TextEditingController();
  final _dailyBikeDiscountController = TextEditingController();

  // Form values
  double? _latitude;
  double? _longitude;
  String _parkingType = 'Car';
  bool _is24x7 = false;
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  String _pricingModel = 'Hourly';
  bool _agreedToTerms = false;

  // Amenities checkboxes
  final Map<String, bool> _amenities = {
    'CCTV': false,
    'Security Guard': false,
    'Covered Parking': false,
    'EV Charging': false,
    'Lighting Availability': false,
    'Washroom Access': false,
  };

  // Images
  final List<XFile> _parkingPhotos = [];
  XFile? _entrancePhoto;
  XFile? _signboardPhoto;

  final List<String> _steps = [
    'Parking Space Details',
    'Slot Capacity',
    'Operational Hours',
    'Amenities & Photos',
    'Pricing',
    'Additional Details & Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'parking_listing_${user.id}';

        // Load basic form data
        _parkingNameController.text = prefs.getString('${userKey}_parkingName') ?? '';
        _parkingAddressController.text = prefs.getString('${userKey}_parkingAddress') ?? '';
        _landmarkController.text = prefs.getString('${userKey}_landmark') ?? '';
        _parkingType = prefs.getString('${userKey}_parkingType') ?? 'Car';
        _is24x7 = prefs.getBool('${userKey}_is24x7') ?? false;
        _pricingModel = prefs.getString('${userKey}_pricingModel') ?? 'Hourly';
        _agreedToTerms = prefs.getBool('${userKey}_agreedToTerms') ?? false;

        // Load slots
        _carSlotsController.text = prefs.getString('${userKey}_carSlots') ?? '';
        _bikeSlotsController.text = prefs.getString('${userKey}_bikeSlots') ?? '';

        // Load rates
        _hourlyCarRateController.text = prefs.getString('${userKey}_hourlyCarRate') ?? '';
        _hourlyBikeRateController.text = prefs.getString('${userKey}_hourlyBikeRate') ?? '';
        _dailyCarRateController.text = prefs.getString('${userKey}_dailyCarRate') ?? '';
        _dailyBikeRateController.text = prefs.getString('${userKey}_dailyBikeRate') ?? '';
        _hourlyCarDiscountController.text = prefs.getString('${userKey}_hourlyCarDiscount') ?? '';
        _hourlyBikeDiscountController.text = prefs.getString('${userKey}_hourlyBikeDiscount') ?? '';
        _dailyCarDiscountController.text = prefs.getString('${userKey}_dailyCarDiscount') ?? '';
        _dailyBikeDiscountController.text = prefs.getString('${userKey}_dailyBikeDiscount') ?? '';

        // Load special instructions
        _specialInstructionsController.text = prefs.getString('${userKey}_specialInstructions') ?? '';

        // Load coordinates
        final lat = prefs.getDouble('${userKey}_latitude');
        final lng = prefs.getDouble('${userKey}_longitude');
        if (lat != null && lng != null) {
          _latitude = lat;
          _longitude = lng;
        }

        // Load amenities
        for (var amenity in _amenities.keys) {
          _amenities[amenity] = prefs.getBool('${userKey}_amenity_$amenity') ?? false;
        }

        // Load current step
        _currentStep = prefs.getInt('${userKey}_currentStep') ?? 0;

        setState(() {});
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'parking_listing_${user.id}';

        // Save basic form data
        await prefs.setString('${userKey}_parkingName', _parkingNameController.text);
        await prefs.setString('${userKey}_parkingAddress', _parkingAddressController.text);
        await prefs.setString('${userKey}_landmark', _landmarkController.text);
        await prefs.setString('${userKey}_parkingType', _parkingType);
        await prefs.setBool('${userKey}_is24x7', _is24x7);
        await prefs.setString('${userKey}_pricingModel', _pricingModel);
        await prefs.setBool('${userKey}_agreedToTerms', _agreedToTerms);

        // Save slots
        await prefs.setString('${userKey}_carSlots', _carSlotsController.text);
        await prefs.setString('${userKey}_bikeSlots', _bikeSlotsController.text);

        // Save rates
        await prefs.setString('${userKey}_hourlyCarRate', _hourlyCarRateController.text);
        await prefs.setString('${userKey}_hourlyBikeRate', _hourlyBikeRateController.text);
        await prefs.setString('${userKey}_dailyCarRate', _dailyCarRateController.text);
        await prefs.setString('${userKey}_dailyBikeRate', _dailyBikeRateController.text);
        await prefs.setString('${userKey}_hourlyCarDiscount', _hourlyCarDiscountController.text);
        await prefs.setString('${userKey}_hourlyBikeDiscount', _hourlyBikeDiscountController.text);
        await prefs.setString('${userKey}_dailyCarDiscount', _dailyCarDiscountController.text);
        await prefs.setString('${userKey}_dailyBikeDiscount', _dailyBikeDiscountController.text);

        // Save special instructions
        await prefs.setString('${userKey}_specialInstructions', _specialInstructionsController.text);

        // Save coordinates
        if (_latitude != null) await prefs.setDouble('${userKey}_latitude', _latitude!);
        if (_longitude != null) await prefs.setDouble('${userKey}_longitude', _longitude!);

        // Save amenities
        for (var entry in _amenities.entries) {
          await prefs.setBool('${userKey}_amenity_${entry.key}', entry.value);
        }

        // Save current step
        await prefs.setInt('${userKey}_currentStep', _currentStep);
      }
    } catch (e) {
      // Handle silently
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

  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    setState(() {
      _parkingPhotos.addAll(images);
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

      // First check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload the file
      await Supabase.instance.client.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Upload error for bucket $bucket, path $path: $e');
      return null;
    }
  }

  void _nextStep() async {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      return;
    }

    // Save form data
    await _saveData();

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _submitListing();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateParkingDetailsStep();
      case 1:
        return _validateSlotCapacityStep();
      case 2:
        return _validateOperationalHoursStep();
      case 3:
        return _validateAmenitiesPhotosStep();
      case 4:
        return _validatePricingStep();
      case 5:
        return _validateFinalStep();
      default:
        return true;
    }
  }

  bool _validateParkingDetailsStep() {
    final nameValid = _parkingNameController.text.trim().isNotEmpty;
    final addressValid = _parkingAddressController.text.trim().isNotEmpty;
    final locationValid = _latitude != null && _longitude != null;

    if (!nameValid || !addressValid || !locationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields in Parking Space Details'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateSlotCapacityStep() {
    final hasCarSlots = _parkingType == 'Car' || _parkingType == 'Both';
    final hasBikeSlots = _parkingType == 'Bike' || _parkingType == 'Both';

    final carSlotsValid = !hasCarSlots || (_carSlotsController.text.isNotEmpty && int.tryParse(_carSlotsController.text) != null && int.parse(_carSlotsController.text) > 0);
    final bikeSlotsValid = !hasBikeSlots || (_bikeSlotsController.text.isNotEmpty && int.tryParse(_bikeSlotsController.text) != null && int.parse(_bikeSlotsController.text) > 0);

    if (!carSlotsValid || !bikeSlotsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid slot capacities'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateOperationalHoursStep() {
    if (!_is24x7 && (_openTime == null || _closeTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set opening and closing times or select 24/7'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateAmenitiesPhotosStep() {
    final hasParkingPhotos = _parkingPhotos.length >= 3 && _parkingPhotos.length <= 10;
    final hasEntrancePhoto = _entrancePhoto != null;

    if (!hasParkingPhotos || !hasEntrancePhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 3 parking photos and 1 entrance photo'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validatePricingStep() {
    // Validate pricing based on model
    bool pricingValid = false;
    switch (_pricingModel) {
      case 'Hourly':
        final hasCarRate = _parkingType == 'Car' || _parkingType == 'Both';
        final hasBikeRate = _parkingType == 'Bike' || _parkingType == 'Both';
        final carRateValid = !hasCarRate || (_hourlyCarRateController.text.isNotEmpty && double.tryParse(_hourlyCarRateController.text) != null);
        final bikeRateValid = !hasBikeRate || (_hourlyBikeRateController.text.isNotEmpty && double.tryParse(_hourlyBikeRateController.text) != null);
        pricingValid = carRateValid && bikeRateValid;
        break;
      case 'Daily':
        final hasCarRate = _parkingType == 'Car' || _parkingType == 'Both';
        final hasBikeRate = _parkingType == 'Bike' || _parkingType == 'Both';
        final carRateValid = !hasCarRate || (_dailyCarRateController.text.isNotEmpty && double.tryParse(_dailyCarRateController.text) != null);
        final bikeRateValid = !hasBikeRate || (_dailyBikeRateController.text.isNotEmpty && double.tryParse(_dailyBikeRateController.text) != null);
        pricingValid = carRateValid && bikeRateValid;
        break;
      case 'Both':
        final hasCarHourly = _parkingType == 'Car' || _parkingType == 'Both';
        final hasBikeHourly = _parkingType == 'Bike' || _parkingType == 'Both';
        final hasCarDaily = _parkingType == 'Car' || _parkingType == 'Both';
        final hasBikeDaily = _parkingType == 'Bike' || _parkingType == 'Both';
        final carHourlyValid = !hasCarHourly || (_hourlyCarRateController.text.isNotEmpty && double.tryParse(_hourlyCarRateController.text) != null);
        final bikeHourlyValid = !hasBikeHourly || (_hourlyBikeRateController.text.isNotEmpty && double.tryParse(_hourlyBikeRateController.text) != null);
        final carDailyValid = !hasCarDaily || (_dailyCarRateController.text.isNotEmpty && double.tryParse(_dailyCarRateController.text) != null);
        final bikeDailyValid = !hasBikeDaily || (_dailyBikeRateController.text.isNotEmpty && double.tryParse(_dailyBikeRateController.text) != null);
        pricingValid = carHourlyValid && bikeHourlyValid && carDailyValid && bikeDailyValid;
        break;
    }

    if (!pricingValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all pricing fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateFinalStep() {
    // Final step validation - just ensure we have all required data
    return true;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload parking photos (required: 3-10 photos)
      final parkingPhotoUrls = <String>[];
      for (var photo in _parkingPhotos) {
        final url = await _uploadFileToSupabase(photo, 'parking_listings', 'parking_photos');
        if (url != null) {
          parkingPhotoUrls.add(url);
        } else {
          throw Exception('Failed to upload parking photo. Please try again.');
        }
      }

      // Ensure we have at least the minimum required photos
      if (parkingPhotoUrls.length < 3) {
        throw Exception('Failed to upload all parking photos. At least 3 photos are required.');
      }

      // Upload entrance photo (required)
      String? entrancePhotoUrl;
      if (_entrancePhoto != null) {
        entrancePhotoUrl = await _uploadFileToSupabase(_entrancePhoto!, 'parking_listings', 'entrance_photos');
        if (entrancePhotoUrl == null) {
          throw Exception('Failed to upload entrance photo. Please try again.');
        }
      } else {
        // This shouldn't happen due to validation, but handle gracefully
        throw Exception('Entrance photo is required but not available');
      }

      // Upload signboard photo (optional)
      String? signboardPhotoUrl;
      if (_signboardPhoto != null) {
        signboardPhotoUrl = await _uploadFileToSupabase(_signboardPhoto!, 'parking_listings', 'signboard_photos');
      }

      // Prepare selected amenities
      final selectedAmenities = _amenities.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Prepare listing data
      final listingData = {
        'host_id': Supabase.instance.client.auth.currentUser!.id,
        'parking_space_name': _parkingNameController.text,
        'parking_address': _parkingAddressController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'landmark': _landmarkController.text.isEmpty ? null : _landmarkController.text,
        'parking_type': _parkingType,
        'total_car_slots': _parkingType == 'Car' || _parkingType == 'Both' ? int.parse(_carSlotsController.text) : null,
        'total_bike_slots': _parkingType == 'Bike' || _parkingType == 'Both' ? int.parse(_bikeSlotsController.text) : null,
        'is_24x7': _is24x7,
        'open_time': !_is24x7 && _openTime != null ? '${_openTime!.hour.toString().padLeft(2, '0')}:${_openTime!.minute.toString().padLeft(2, '0')}:00' : null,
        'close_time': !_is24x7 && _closeTime != null ? '${_closeTime!.hour.toString().padLeft(2, '0')}:${_closeTime!.minute.toString().padLeft(2, '0')}:00' : null,
        'amenities': selectedAmenities,
        'parking_photos': parkingPhotoUrls,
        'entrance_photo_url': entrancePhotoUrl,
        'signboard_photo_url': signboardPhotoUrl,
        'pricing_model': _pricingModel,
        'hourly_rate_car': _pricingModel == 'Hourly' || _pricingModel == 'Both' ? double.parse(_hourlyCarRateController.text) : null,
        'hourly_rate_bike': _pricingModel == 'Hourly' || _pricingModel == 'Both' ? double.parse(_hourlyBikeRateController.text) : null,
        'daily_rate_car': _pricingModel == 'Daily' || _pricingModel == 'Both' ? double.parse(_dailyCarRateController.text) : null,
        'daily_rate_bike': _pricingModel == 'Daily' || _pricingModel == 'Both' ? double.parse(_dailyBikeRateController.text) : null,
        'special_instructions': _specialInstructionsController.text.isEmpty ? null : _specialInstructionsController.text,
        'agreed_to_terms': _agreedToTerms,
        'status': 'pending',
      };

      // Save to Supabase
      await Supabase.instance.client.from('listings').insert(listingData);

      // Clear saved data
      await _clearSavedData();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/listing_approval_waiting');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating listing: $e'),
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

  Future<void> _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userKey = 'parking_listing_${user.id}';
        // Clear all saved data for this user
        final keys = prefs.getKeys().where((key) => key.startsWith(userKey));
        for (var key in keys) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Handle silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Create Listing',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.grey[700],
              size: 20,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Modern Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Step dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? const Color(0xFF6366F1)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Step counter
                  Text(
                    '${_currentStep + 1} of ${_steps.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Step content with smooth animation
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      )),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // Modern Navigation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: _currentStep == 0
                    ? Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentStep == _steps.length - 1 ? 'Create Listing' : 'Continue',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_currentStep < _steps.length - 1) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextButton(
                                onPressed: _isLoading ? null : _previousStep,
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currentStep == _steps.length - 1 ? 'Create Listing' : 'Continue',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (_currentStep < _steps.length - 1) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
        return ParkingDetailsStep(
          nameController: _parkingNameController,
          addressController: _parkingAddressController,
          landmarkController: _landmarkController,
          parkingType: _parkingType,
          onParkingTypeChanged: (type) => setState(() => _parkingType = type),
          latitude: _latitude,
          longitude: _longitude,
          isLoadingLocation: _isLoadingLocation,
          onGetLocation: () async {
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
            }
          },
        );
      case 1:
        return SlotCapacityStep(
          carSlotsController: _carSlotsController,
          bikeSlotsController: _bikeSlotsController,
          parkingType: _parkingType,
        );
      case 2:
        return OperationalHoursStep(
          is24x7: _is24x7,
          on24x7Changed: (value) => setState(() => _is24x7 = value),
          openTime: _openTime,
          closeTime: _closeTime,
          onOpenTimeChanged: (time) => setState(() => _openTime = time),
          onCloseTimeChanged: (time) => setState(() => _closeTime = time),
        );
      case 3:
        return AmenitiesPhotosStep(
          amenities: _amenities,
          onAmenityChanged: (amenity, value) => setState(() => _amenities[amenity] = value),
          parkingPhotos: _parkingPhotos,
          onAddParkingPhoto: (photo) => setState(() => _parkingPhotos.add(photo)),
          onRemoveParkingPhoto: (index) => setState(() => _parkingPhotos.removeAt(index)),
          entrancePhoto: _entrancePhoto,
          signboardPhoto: _signboardPhoto,
          onPhotoChanged: (type, photo) => setState(() {
            if (type == 'entrance') {
              _entrancePhoto = photo;
            } else if (type == 'signboard') {
              _signboardPhoto = photo;
            }
          }),
        );
      case 4:
        return PricingStep(
          pricingModel: _pricingModel,
          onPricingModelChanged: (model) => setState(() => _pricingModel = model),
          hourlyCarRateController: _hourlyCarRateController,
          hourlyBikeRateController: _hourlyBikeRateController,
          dailyCarRateController: _dailyCarRateController,
          dailyBikeRateController: _dailyBikeRateController,
          hourlyCarDiscountController: _hourlyCarDiscountController,
          hourlyBikeDiscountController: _hourlyBikeDiscountController,
          dailyCarDiscountController: _dailyCarDiscountController,
          dailyBikeDiscountController: _dailyBikeDiscountController,
          parkingType: _parkingType,
        );
      case 5:
        return AdditionalDetailsStep(
          specialInstructionsController: _specialInstructionsController,
          parkingName: _parkingNameController.text,
          parkingType: _parkingType,
          pricingModel: _pricingModel,
          is24x7: _is24x7,
          openTime: _openTime,
          closeTime: _closeTime,
          parkingPhotos: _parkingPhotos,
          amenities: _amenities,
          hourlyCarRateController: _pricingModel == 'Hourly' || _pricingModel == 'Both' ? _hourlyCarRateController : null,
          dailyCarRateController: _pricingModel == 'Daily' || _pricingModel == 'Both' ? _dailyCarRateController : null,
        );
      default:
        return const SizedBox();
    }
  }



  @override
  void dispose() {
    _parkingNameController.dispose();
    _parkingAddressController.dispose();
    _landmarkController.dispose();
    _carSlotsController.dispose();
    _bikeSlotsController.dispose();
    _specialInstructionsController.dispose();
    _hourlyCarRateController.dispose();
    _hourlyBikeRateController.dispose();
    _dailyCarRateController.dispose();
    _dailyBikeRateController.dispose();
    _hourlyCarDiscountController.dispose();
    _hourlyBikeDiscountController.dispose();
    _dailyCarDiscountController.dispose();
    _dailyBikeDiscountController.dispose();
    super.dispose();
  }
}
