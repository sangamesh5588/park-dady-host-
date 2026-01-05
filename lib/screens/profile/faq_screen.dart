import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I list my parking space?',
      'answer': 'To list your parking space, go to the home screen and tap "Add Parking Space". Fill in the required details including location, pricing, availability, and photos. Once submitted, our team will review and approve your listing within 24-48 hours.'
    },
    {
      'question': 'What are the requirements to become a host?',
      'answer': 'To become a host, you need to be at least 18 years old, have legal ownership or permission to rent the parking space, and provide valid identification. You\'ll also need to complete our host onboarding process.'
    },
    {
      'question': 'How do I set my pricing?',
      'answer': 'You can set your own pricing based on location, demand, and amenities. We suggest checking similar parking spaces in your area for competitive rates. Prices can be set per hour, daily, or monthly.'
    },
    {
      'question': 'How do I receive payments?',
      'answer': 'Payments are processed securely through our platform. Funds are typically transferred to your linked bank account or digital wallet within 24-48 hours after the booking is completed and the customer checks out.'
    },
    {
      'question': 'What happens if there\'s a dispute?',
      'answer': 'If there\'s a dispute, contact our support team immediately with photos and details. We\'ll review the situation and work to resolve it fairly for both parties. Our resolution process typically takes 24-72 hours.'
    },
    {
      'question': 'Can I cancel a booking?',
      'answer': 'You can cancel a booking up to 2 hours before the scheduled time for a full refund. Cancellations made less than 2 hours in advance may incur a cancellation fee. Always communicate with your guests directly.'
    },
    {
      'question': 'What insurance do I need?',
      'answer': 'While we provide basic coverage for listed spaces, we recommend hosts obtain their own liability insurance for additional protection. You can find more details in our host insurance guide.'
    },
    {
      'question': 'How do I update my listing?',
      'answer': 'Go to your profile, select "My Parking Spaces", choose the listing you want to update, and tap "Edit". You can modify pricing, availability, photos, and other details. Changes are reviewed before going live.'
    },
  ];

  final List<bool> _expandedStates = [];

  @override
  void initState() {
    super.initState();
    _expandedStates.addAll(List.generate(_faqs.length, (index) => false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shadowColor: const Color(0x1F000000),
            elevation: 2,
          ),
        ),
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              title: Text(
                _faqs[index]['question']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              trailing: Icon(
                _expandedStates[index]
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFFA4A5A6),
              ),
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedStates[index] = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    _faqs[index]['answer']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
