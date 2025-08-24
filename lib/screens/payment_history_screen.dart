import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart' as monetization;

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'subscription', 'boost', 'unblock'];
  
  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Transactions';
      case 'subscription':
        return 'Subscriptions';
      case 'boost':
        return 'Boosts';
      case 'unblock':
        return 'Unblocks';
      default:
        return filter;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return Icons.star;
      case 'boost':
        return Icons.trending_up;
      case 'unblock':
        return Icons.lock_open;
      default:
        return Icons.payment;
    }
  }

  String _formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return 'Subscription';
      case 'boost':
        return 'Boost';
      case 'unblock':
        return 'Account Unblock';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text(
                        _getFilterDisplayName(filter),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: Colors.blue.shade600,
                      backgroundColor: Colors.grey.shade200,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          
          // Transactions list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading payment history',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No payment history',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Your transactions will appear here',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter transactions
                List<DocumentSnapshot> filteredDocs = snapshot.data!.docs;
                if (_selectedFilter != 'all') {
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['type']?.toString().toLowerCase() == _selectedFilter;
                  }).toList();
                }

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No ${_getFilterDisplayName(_selectedFilter).toLowerCase()}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final transaction = monetization.Transaction.fromMap(
                      doc.data() as Map<String, dynamic>
                    );

                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  _getTransactionIcon(transaction.type),
                                  size: 20.sp,
                                  color: _getStatusColor(transaction.status),
                                ),
                              ),
                              
                              SizedBox(width: 12.w),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTransactionType(transaction.type),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    
                                    if (transaction.metadata?['description'] != null) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        transaction.metadata!['description'],
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${transaction.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  
                                  SizedBox(height: 2.h),
                                  
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(transaction.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      transaction.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(transaction.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 12.h),
                          
                          Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          
                          SizedBox(height: 12.h),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year} '
                                '${transaction.createdAt.hour.toString().padLeft(2, '0')}:'
                                '${transaction.createdAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              
                              Spacer(),
                              
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 14.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'ID: ${transaction.transactionId}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
