import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// App Color Scheme Constants
const Color primaryOlive = Color(0xFFB3B760);
const Color darkGreen = Color(0xFF064232);
const Color primaryBlack = Color(0xFF000000);

enum MessageType {
  success,
  error,
  warning,
  info,
}

class BeautifulMessage {
  static void show(
    BuildContext context, {
    required String message,
    required MessageType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = primaryOlive.withOpacity(0.1);
        iconColor = primaryOlive;
        icon = Icons.check_circle_rounded;
        break;
      case MessageType.error:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        icon = Icons.error_rounded;
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade600;
        icon = Icons.warning_rounded;
        break;
      case MessageType.info:
        backgroundColor = darkGreen.withOpacity(0.1);
        iconColor = darkGreen;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: iconColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        duration: duration,
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: MessageType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: MessageType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: MessageType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: MessageType.info);
  }
}

// Extension pentru Dialog-uri frumoase
class BeautifulDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required MessageType type,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    Color iconColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        iconColor = primaryOlive;
        icon = Icons.check_circle_rounded;
        break;
      case MessageType.error:
        iconColor = Colors.red.shade600;
        icon = Icons.error_rounded;
        break;
      case MessageType.warning:
        iconColor = Colors.orange.shade600;
        icon = Icons.warning_rounded;
        break;
      case MessageType.info:
        iconColor = darkGreen;
        icon = Icons.info_rounded;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          contentPadding: EdgeInsets.all(24.w),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon at top
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 48.sp,
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            onCancel ?? () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm ?? () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        confirmText ?? 'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: MessageType.success,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: MessageType.error,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  static void showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: MessageType.warning,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
