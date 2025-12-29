import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PricingStep extends StatefulWidget {
  final String pricingModel;
  final Function(String) onPricingModelChanged;
  final TextEditingController hourlyCarRateController;
  final TextEditingController hourlyBikeRateController;
  final TextEditingController dailyCarRateController;
  final TextEditingController dailyBikeRateController;
  final TextEditingController hourlyCarDiscountController;
  final TextEditingController hourlyBikeDiscountController;
  final TextEditingController dailyCarDiscountController;
  final TextEditingController dailyBikeDiscountController;
  final String parkingType;

  const PricingStep({
    super.key,
    required this.pricingModel,
    required this.onPricingModelChanged,
    required this.hourlyCarRateController,
    required this.hourlyBikeRateController,
    required this.dailyCarRateController,
    required this.dailyBikeRateController,
    required this.hourlyCarDiscountController,
    required this.hourlyBikeDiscountController,
    required this.dailyCarDiscountController,
    required this.dailyBikeDiscountController,
    required this.parkingType,
  });

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  bool _hourlyCarOriginalFilled = false;
  bool _hourlyBikeOriginalFilled = false;
  bool _dailyCarOriginalFilled = false;
  bool _dailyBikeOriginalFilled = false;

  bool get showHourly => widget.pricingModel == 'Hourly' || widget.pricingModel == 'Both';
  bool get showDaily => widget.pricingModel == 'Daily' || widget.pricingModel == 'Both';
  bool get hasCarRates => widget.parkingType == 'Car' || widget.parkingType == 'Both';
  bool get hasBikeRates => widget.parkingType == 'Bike' || widget.parkingType == 'Both';

  @override
  void initState() {
    super.initState();
    _initializeFieldStates();
    _addListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _initializeFieldStates() {
    _hourlyCarOriginalFilled = widget.hourlyCarRateController.text.isNotEmpty;
    _hourlyBikeOriginalFilled = widget.hourlyBikeRateController.text.isNotEmpty;
    _dailyCarOriginalFilled = widget.dailyCarRateController.text.isNotEmpty;
    _dailyBikeOriginalFilled = widget.dailyBikeRateController.text.isNotEmpty;
  }

  void _addListeners() {
    widget.hourlyCarRateController.addListener(_onHourlyCarOriginalChanged);
    widget.hourlyBikeRateController.addListener(_onHourlyBikeOriginalChanged);
    widget.dailyCarRateController.addListener(_onDailyCarOriginalChanged);
    widget.dailyBikeRateController.addListener(_onDailyBikeOriginalChanged);
  }

  void _removeListeners() {
    widget.hourlyCarRateController.removeListener(_onHourlyCarOriginalChanged);
    widget.hourlyBikeRateController.removeListener(_onHourlyBikeOriginalChanged);
    widget.dailyCarRateController.removeListener(_onDailyCarOriginalChanged);
    widget.dailyBikeRateController.removeListener(_onDailyBikeOriginalChanged);
  }

  void _onHourlyCarOriginalChanged() {
    final isFilled = widget.hourlyCarRateController.text.isNotEmpty;
    if (_hourlyCarOriginalFilled != isFilled) {
      setState(() {
        _hourlyCarOriginalFilled = isFilled;
        // Clear discount if original is empty
        if (!isFilled) {
          widget.hourlyCarDiscountController.clear();
        }
      });
    }
  }

  void _onHourlyBikeOriginalChanged() {
    final isFilled = widget.hourlyBikeRateController.text.isNotEmpty;
    if (_hourlyBikeOriginalFilled != isFilled) {
      setState(() {
        _hourlyBikeOriginalFilled = isFilled;
        if (!isFilled) {
          widget.hourlyBikeDiscountController.clear();
        }
      });
    }
  }

  void _onDailyCarOriginalChanged() {
    final isFilled = widget.dailyCarRateController.text.isNotEmpty;
    if (_dailyCarOriginalFilled != isFilled) {
      setState(() {
        _dailyCarOriginalFilled = isFilled;
        if (!isFilled) {
          widget.dailyCarDiscountController.clear();
        }
      });
    }
  }

  void _onDailyBikeOriginalChanged() {
    final isFilled = widget.dailyBikeRateController.text.isNotEmpty;
    if (_dailyBikeOriginalFilled != isFilled) {
      setState(() {
        _dailyBikeOriginalFilled = isFilled;
        if (!isFilled) {
          widget.dailyBikeDiscountController.clear();
        }
      });
    }
  }

  // Custom input formatter to restrict discounted price to be less than original price
  TextInputFormatter _createDiscountFormatter(String originalPriceText) {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (newValue.text.isEmpty) return newValue;

      final originalPrice = double.tryParse(originalPriceText);
      if (originalPrice == null) return newValue;

      final newDiscountPrice = double.tryParse(newValue.text);
      if (newDiscountPrice == null) return newValue;

      // If the new value would be >= original price, don't allow it
      if (newDiscountPrice >= originalPrice) {
        return oldValue; // Keep the old value
      }

      return newValue; // Allow the new value
    });
  }

  Widget _buildDiscountDisplay(String originalText, String discountedText) {
    final original = double.tryParse(originalText);
    final discounted = double.tryParse(discountedText);

    if (original == null || discounted == null || original <= discounted) {
      return const SizedBox.shrink();
    }

    final discountAmount = original - discounted;
    final discountPercentage = ((discountAmount / original) * 100).round();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.discount,
            color: Colors.green[600],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Save ₹${discountAmount.toStringAsFixed(0)} (${discountPercentage}%)',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Card with smooth entrance
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05 * value),
                        blurRadius: 12 * value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set Your Pricing',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Choose your pricing model and rates',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Pricing Model Card with staggered animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05 * value),
                        blurRadius: 12 * value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.price_change,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Pricing Model',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: ['Hourly', 'Daily', 'Both'].asMap().entries.map((entry) {
                          final index = entry.key;
                          final model = entry.value;
                          final isSelected = widget.pricingModel == model;

                          return Expanded(
                            child: TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutQuart,
                              builder: (context, cardValue, child) {
                                return Transform.scale(
                                  scale: 0.8 + (0.2 * cardValue),
                                  child: Opacity(
                                    opacity: cardValue,
                                    child: GestureDetector(
                                      onTap: () => widget.onPricingModelChanged(model),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.grey[50],
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              model == 'Hourly' ? Icons.schedule :
                                              model == 'Daily' ? Icons.calendar_today : Icons.swap_horiz,
                                              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                                              size: 24,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              model,
                                              style: TextStyle(
                                                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[700],
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Rate Settings Cards
        if (showHourly) ...[
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hourly Rates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (hasCarRates) ...[
                  // Car Parking Section
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Car Parking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Car Original Price
                  TextFormField(
                    controller: widget.hourlyCarRateController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Original Price',
                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: hasCarRates && showHourly ? (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = double.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be greater than 0';
                      return null;
                    } : null,
                  ),

                  const SizedBox(height: 12),

                  // Car Discounted Price
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.hourlyCarRateController,
                    builder: (context, value, child) {
                      return TextFormField(
                        controller: widget.hourlyCarDiscountController,
                        enabled: _hourlyCarOriginalFilled,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _hourlyCarOriginalFilled ? Colors.black : Colors.grey[400],
                        ),
                        decoration: InputDecoration(
                          labelText: _hourlyCarOriginalFilled ? 'Discounted Price *' : 'Fill original price first',
                          labelStyle: TextStyle(
                            color: _hourlyCarOriginalFilled ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 13,
                          ),
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _hourlyCarOriginalFilled ? Colors.black : Colors.grey[400],
                          ),
                          helperText: _hourlyCarOriginalFilled && value.text.isNotEmpty
                              ? 'Must be less than ₹${value.text}'
                              : null,
                          helperStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _hourlyCarOriginalFilled ? Colors.grey[300]! : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _hourlyCarOriginalFilled ? Colors.grey[50] : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: _hourlyCarOriginalFilled
                            ? [_createDiscountFormatter(value.text)]
                            : [],
                        validator: hasCarRates && showHourly ? (val) {
                          if (val?.isEmpty ?? true) {
                            return _hourlyCarOriginalFilled ? 'Required' : null;
                          }
                          final num = double.tryParse(val!);
                          if (num == null || num <= 0) return 'Must be greater than 0';
                          final originalNum = double.tryParse(value.text);
                          if (originalNum != null && num >= originalNum) {
                            return 'Must be less than ₹${value.text}';
                          }
                          return null;
                        } : null,
                      );
                    },
                  ),

                  // Car Discount Display
                  if (_hourlyCarOriginalFilled && widget.hourlyCarDiscountController.text.isNotEmpty)
                    _buildDiscountDisplay(widget.hourlyCarRateController.text, widget.hourlyCarDiscountController.text),

                  if (hasBikeRates) const SizedBox(height: 24),
                ],

                if (hasBikeRates) ...[
                  // Bike Parking Section
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bike Parking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bike Original Price
                  TextFormField(
                    controller: widget.hourlyBikeRateController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Original Price',
                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: hasBikeRates && showHourly ? (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = double.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be greater than 0';
                      return null;
                    } : null,
                  ),

                  const SizedBox(height: 12),

                  // Bike Discounted Price
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.hourlyBikeRateController,
                    builder: (context, value, child) {
                      return TextFormField(
                        controller: widget.hourlyBikeDiscountController,
                        enabled: _hourlyBikeOriginalFilled,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _hourlyBikeOriginalFilled ? Colors.black : Colors.grey[400],
                        ),
                        decoration: InputDecoration(
                          labelText: _hourlyBikeOriginalFilled ? 'Discounted Price *' : 'Fill original price first',
                          labelStyle: TextStyle(
                            color: _hourlyBikeOriginalFilled ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 13,
                          ),
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _hourlyBikeOriginalFilled ? Colors.black : Colors.grey[400],
                          ),
                          helperText: _hourlyBikeOriginalFilled && value.text.isNotEmpty
                              ? 'Must be less than ₹${value.text}'
                              : null,
                          helperStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _hourlyBikeOriginalFilled ? Colors.grey[300]! : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _hourlyBikeOriginalFilled ? Colors.grey[50] : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: _hourlyBikeOriginalFilled
                            ? [_createDiscountFormatter(value.text)]
                            : [],
                        validator: hasBikeRates && showHourly ? (val) {
                          if (val?.isEmpty ?? true) {
                            return _hourlyBikeOriginalFilled ? 'Required' : null;
                          }
                          final num = double.tryParse(val!);
                          if (num == null || num <= 0) return 'Must be greater than 0';
                          final originalNum = double.tryParse(value.text);
                          if (originalNum != null && num >= originalNum) {
                            return 'Must be less than ₹${value.text}';
                          }
                          return null;
                        } : null,
                      );
                    },
                  ),

                  // Bike Discount Display
                  if (_hourlyBikeOriginalFilled && widget.hourlyBikeDiscountController.text.isNotEmpty)
                    _buildDiscountDisplay(widget.hourlyBikeRateController.text, widget.hourlyBikeDiscountController.text),
                ],
              ],
            ),
          ),
        ],

        if (showDaily) ...[
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Daily Rates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (hasCarRates) ...[
                  // Daily Car Parking Section
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Car Parking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily Car Original Price
                  TextFormField(
                    controller: widget.dailyCarRateController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Original Price',
                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: hasCarRates && showDaily ? (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = double.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be greater than 0';
                      return null;
                    } : null,
                  ),

                  const SizedBox(height: 12),

                  // Daily Car Discounted Price
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.dailyCarRateController,
                    builder: (context, value, child) {
                      return TextFormField(
                        controller: widget.dailyCarDiscountController,
                        enabled: _dailyCarOriginalFilled,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _dailyCarOriginalFilled ? Colors.black : Colors.grey[400],
                        ),
                        decoration: InputDecoration(
                          labelText: _dailyCarOriginalFilled ? 'Discounted Price *' : 'Fill original price first',
                          labelStyle: TextStyle(
                            color: _dailyCarOriginalFilled ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 13,
                          ),
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _dailyCarOriginalFilled ? Colors.black : Colors.grey[400],
                          ),
                          helperText: _dailyCarOriginalFilled && value.text.isNotEmpty
                              ? 'Must be less than ₹${value.text}'
                              : null,
                          helperStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _dailyCarOriginalFilled ? Colors.grey[300]! : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _dailyCarOriginalFilled ? Colors.grey[50] : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: _dailyCarOriginalFilled
                            ? [_createDiscountFormatter(value.text)]
                            : [],
                        validator: hasCarRates && showDaily ? (val) {
                          if (val?.isEmpty ?? true) {
                            return _dailyCarOriginalFilled ? 'Required' : null;
                          }
                          final num = double.tryParse(val!);
                          if (num == null || num <= 0) return 'Must be greater than 0';
                          final originalNum = double.tryParse(value.text);
                          if (originalNum != null && num >= originalNum) {
                            return 'Must be less than ₹${value.text}';
                          }
                          return null;
                        } : null,
                      );
                    },
                  ),

                  // Daily Car Discount Display
                  if (_dailyCarOriginalFilled && widget.dailyCarDiscountController.text.isNotEmpty)
                    _buildDiscountDisplay(widget.dailyCarRateController.text, widget.dailyCarDiscountController.text),

                  if (hasBikeRates) const SizedBox(height: 24),
                ],

                if (hasBikeRates) ...[
                  // Daily Bike Parking Section
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bike Parking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily Bike Original Price
                  TextFormField(
                    controller: widget.dailyBikeRateController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Original Price',
                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: hasBikeRates && showDaily ? (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = double.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be greater than 0';
                      return null;
                    } : null,
                  ),

                  const SizedBox(height: 12),

                  // Daily Bike Discounted Price
                  TextFormField(
                    controller: widget.dailyBikeDiscountController,
                    enabled: _dailyBikeOriginalFilled,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _dailyBikeOriginalFilled ? Colors.black : Colors.grey[400],
                    ),
                    decoration: InputDecoration(
                      labelText: _dailyBikeOriginalFilled ? 'Discounted Price *' : 'Fill original price first',
                      labelStyle: TextStyle(
                        color: _dailyBikeOriginalFilled ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _dailyBikeOriginalFilled ? Colors.black : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _dailyBikeOriginalFilled ? Colors.grey[300]! : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                      ),
                      filled: true,
                      fillColor: _dailyBikeOriginalFilled ? Colors.grey[50] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _dailyBikeOriginalFilled
                        ? [_createDiscountFormatter(widget.dailyBikeRateController.text)]
                        : [],
                    validator: hasBikeRates && showDaily ? (value) {
                      if (value?.isEmpty ?? true) {
                        if (_dailyBikeOriginalFilled) {
                          return 'Required';
                        }
                        return null; // Don't validate if original price not filled
                      }
                      final num = double.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be greater than 0';
                      final originalNum = double.tryParse(widget.dailyBikeRateController.text);
                      if (originalNum != null && num >= originalNum) {
                        return 'Must be less than original price';
                      }
                      return null;
                    } : null,
                  ),

                  // Daily Bike Discount Display
                  if (_dailyBikeOriginalFilled && widget.dailyBikeDiscountController.text.isNotEmpty)
                    _buildDiscountDisplay(widget.dailyBikeRateController.text, widget.dailyBikeDiscountController.text),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 40), // Extra spacing for bottom nav
      ],
    );
  }
}
