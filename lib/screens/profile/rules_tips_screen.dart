import 'package:flutter/material.dart';

class RulesTipsScreen extends StatelessWidget {
  const RulesTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shadowColor: const Color(0x1F000000),
            elevation: 2,
          ),
        ),
        title: const Text(
          'Rules & Tips',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionCard(
            title: 'Parking Rules',
            icon: Icons.rule,
            color: const Color(0xFFD96F4A),
            items: [
              'Park within designated lines only',
              'Do not block driveways or emergency exits',
              'Respect time limits and parking fees',
              'Keep your vehicle locked and secure',
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Safety Tips',
            icon: Icons.security,
            color: const Color(0xFF4CAF50),
            items: [
              'Park in well-lit areas when possible',
              'Remove valuables from your vehicle',
              'Take photos of your parking spot',
              'Note nearby landmarks for reference',
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Booking Best Practices',
            icon: Icons.lightbulb,
            color: const Color(0xFF2196F3),
            items: [
              'Book in advance during peak hours',
              'Arrive on time to avoid fines',
              'Extend booking if needed',
              'Rate and review parking spaces',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2B2B2B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item != items.last) const Divider(height: 1, indent: 38),
            ],
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
