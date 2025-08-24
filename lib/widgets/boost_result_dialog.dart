import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BoostResultDialog extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String? boostName;
  final int? duration;
  final VoidCallback? onOkPressed;

  const BoostResultDialog({
    Key? key,
    required this.isSuccess,
    required this.title,
    required this.message,
    this.boostName,
    this.duration,
    this.onOkPressed,
  }) : super(key: key);

  @override
  _BoostResultDialogState createState() => _BoostResultDialogState();
}

class _BoostResultDialogState extends State<BoostResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _scaleController;
  late Animation<double> _iconAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));

    // Start animations
    _scaleController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isSuccess
                    ? [
                        Color(0xFFB3B760).withOpacity(0.1),
                        Color(0xFF064232).withOpacity(0.05),
                      ]
                    : [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: _iconAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _iconAnimation.value,
                    child: Container(
                      height: 120.h,
                      width: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSuccess
                            ? Color(0xFFB3B760).withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                      ),
                      child: Icon(
                        widget.isSuccess
                            ? Icons.check_circle
                            : Icons.error_outline,
                        size: 80.sp,
                        color: widget.isSuccess
                            ? Color(0xFFB3B760)
                            : Colors.red[600],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isSuccess ? Color(0xFF064232) : Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                // Message
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Boost details (only for success)
                if (widget.isSuccess &&
                    widget.boostName != null &&
                    widget.duration != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Color(0xFFB3B760).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Color(0xFFB3B760).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFB3B760),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Boost: ${widget.boostName}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF064232),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Color(0xFFB3B760),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Duration: ${widget.duration} days',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Color(0xFF064232),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        widget.onOkPressed ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isSuccess
                          ? Color(0xFFB3B760)
                          : Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      widget.isSuccess ? 'Great!' : 'Try Again',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String boostName,
    required int duration,
    VoidCallback? onOkPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BoostResultDialog(
        isSuccess: true,
        title: '🎉 Boost Activated!',
        message:
            'Your boost has been successfully activated and is now live on your listing.',
        boostName: boostName,
        duration: duration,
        onOkPressed: onOkPressed,
      ),
    );
  }

  // Helper method to show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String errorMessage,
    VoidCallback? onOkPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BoostResultDialog(
        isSuccess: false,
        title: 'Boost Failed',
        message: errorMessage,
        onOkPressed: onOkPressed,
      ),
    );
  }
}
