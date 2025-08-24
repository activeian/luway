import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/car.dart';
import '../services/ownership_verification_service.dart';

class OwnershipVerificationCard extends StatefulWidget {
  final Car car;
  final VoidCallback onCarRemoved;
  final VoidCallback onCarVerified;

  const OwnershipVerificationCard({
    super.key,
    required this.car,
    required this.onCarRemoved,
    required this.onCarVerified,
  });

  @override
  State<OwnershipVerificationCard> createState() =>
      _OwnershipVerificationCardState();
}

class _OwnershipVerificationCardState extends State<OwnershipVerificationCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final daysUntilVerification =
        OwnershipVerificationService.getDaysUntilNextVerification(widget.car);
    final isExpired =
        OwnershipVerificationService.hasExpiredVerification(widget.car);
    final needsSoon =
        OwnershipVerificationService.needsVerificationSoon(widget.car);

    // Nu afișa card-ul dacă nu necesită verificare
    if (!isExpired && !needsSoon) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isExpired ? Colors.red[300]! : Colors.orange[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? Colors.red : Colors.orange).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header cu iconă și titlu
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: (isExpired ? Colors.red : Colors.orange)[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isExpired ? Icons.warning : Icons.access_time,
                    color: isExpired ? Colors.red[600] : Colors.orange[600],
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpired
                            ? 'Verification Required'
                            : 'Verification Soon',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              isExpired ? Colors.red[700] : Colors.orange[700],
                        ),
                      ),
                      Text(
                        '${widget.car.brand} ${widget.car.model} - ${widget.car.plateNumber}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Mesajul de verificare
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExpired
                        ? 'Verification overdue by ${-daysUntilVerification} days!'
                        : 'Verification needed in $daysUntilVerification days',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Do you still own this car? Please confirm to keep it in your garage.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Butoane de acțiune
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleDeclineOwnership,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[400]!),
                      foregroundColor: Colors.red[600],
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red[600],
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, size: 16.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'No, Remove Car',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirmOwnership,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFb3b760),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 16.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'Yes, I Own It',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmOwnership() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await OwnershipVerificationService.confirmOwnership(widget.car.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Ownership confirmed! Next verification in 2 months.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );

        widget.onCarVerified();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Failed to confirm ownership. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeclineOwnership() async {
    // Confirmă ștergerea
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red[600],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Remove Car',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you no longer own ${widget.car.brand} ${widget.car.model} (${widget.car.plateNumber})?\n\nThis action cannot be undone.',
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Remove Car'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await OwnershipVerificationService.declineOwnership(widget.car.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Car removed from your garage.'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );

        widget.onCarRemoved();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Failed to remove car. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
