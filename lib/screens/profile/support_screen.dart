import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'faq_screen.dart';
import 'contact_support_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog(context, 'Unable to make phone call. Please check if your device supports phone calls.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to launch phone dialer. Please try again.');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, BuildContext context) async {
    try {
      final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=Hi, I need help with ParkingHost app.');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web WhatsApp
        final Uri webWhatsappUri = Uri.parse('https://web.whatsapp.com/send?phone=$phoneNumber&text=Hi, I need help with ParkingHost app.');
        if (await canLaunchUrl(webWhatsappUri)) {
          await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog(context, 'Unable to open WhatsApp. Please make sure WhatsApp is installed on your device.');
        }
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to open WhatsApp. Please try again.');
    }
  }

  Future<void> _sendEmail(String email, BuildContext context) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'ParkingHost Support Request',
          'body': 'Hello ParkingHost Support Team,\n\nPlease describe your issue here...\n\nApp Version: 1.0.0\nDevice: Android/iOS\n\nBest regards,',
        },
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog(context, 'Unable to open email app. Please send an email to $email manually.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to open email app. Please try again.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unable to Proceed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
          'Support & Help',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSupportItem(
            icon: Icons.help_outline,
            title: 'FAQs',
            subtitle: 'Find answers to common questions',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FAQScreen()),
            ),
          ),
          _buildSupportItem(
            icon: Icons.chat_bubble_outline,
            title: 'Contact Support',
            subtitle: 'Get help from our support team',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
            ),
          ),
          _buildSupportItem(
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: 'Speak directly with our team',
            onTap: () => _makePhoneCall('+91-9876543210', context),
          ),
          _buildSupportItem(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Send us an email',
            onTap: () => _sendEmail('support@parkinghost.com', context),
          ),
          _buildSupportItem(
            icon: Icons.chat,
            title: 'WhatsApp Support',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () => _openWhatsApp('919876543210', context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B5160),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2B2B2B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFA4A5A6),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFA4A5A6),
        ),
        onTap: onTap,
      ),
    );
  }
}
