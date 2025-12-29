import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    // TODO: Load transactions from database
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _transactions = [
          {
            'id': '1',
            'type': 'payment',
            'description': 'Parking at Downtown Space A1',
            'amount': -10.00,
            'date': DateTime.now().subtract(const Duration(hours: 2)),
            'status': 'completed',
          },
          {
            'id': '2',
            'type': 'earning',
            'description': 'Booking from John Smith',
            'amount': 15.00,
            'date': DateTime.now().subtract(const Duration(days: 1)),
            'status': 'completed',
          },
          {
            'id': '3',
            'type': 'payment',
            'description': 'Parking at Mall Level 2',
            'amount': -7.00,
            'date': DateTime.now().subtract(const Duration(days: 2)),
            'status': 'completed',
          },
          {
            'id': '4',
            'type': 'refund',
            'description': 'Refund for cancelled booking',
            'amount': 12.00,
            'date': DateTime.now().subtract(const Duration(days: 3)),
            'status': 'completed',
          },
        ];
        _isLoading = false;
      });
    }
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shadowColor: const Color(0x1F000000),
            elevation: 2,
          ),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF6366F1)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filter transactions - Coming soon!')),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD96F4A),
              ),
            )
          : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 48,
              color: Color(0xFF3B5160),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your payment history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFA4A5A6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
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
                color: _getTransactionColor(transaction['type']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionIcon(transaction['type']),
                color: _getTransactionColor(transaction['type']),
                size: 20,
              ),
            ),
            title: Text(
              transaction['description'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2B2B),
              ),
            ),
            subtitle: Text(
              _formatDate(transaction['date']),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFA4A5A6),
              ),
            ),
            trailing: Text(
              '${transaction['amount'] >= 0 ? '+' : ''}\$${transaction['amount'].abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction['amount'] >= 0
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2B2B2B),
              ),
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View ${transaction['description']} details - Coming soon!')),
            ),
          ),
        );
      },
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'payment':
        return const Color(0xFFFF4444);
      case 'earning':
        return const Color(0xFF4CAF50);
      case 'refund':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF3B5160);
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'earning':
        return Icons.attach_money;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
