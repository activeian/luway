import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

const Color oliveColor = Color(0xFFB3B760);

class ChatConversationScreen extends StatefulWidget {
  final String receiverId;
  final String? carPlateNumber;
  final String? carBrand;
  final String? conversationId; // Add conversationId parameter

  const ChatConversationScreen({
    super.key,
    required this.receiverId,
    this.carPlateNumber,
    this.carBrand,
    this.conversationId, // Add to constructor
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  bool _showQuickMessages = false;
  bool _isUserBlocked = false;
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;
  String? _otherUserNickname;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.markMessagesAsRead(_currentUserId, widget.receiverId);
      _checkIfUserBlocked();
      _loadOtherUserStatus();
    });
  }

  Future<void> _checkIfUserBlocked() async {
    final blocked =
        await ChatService.isUserBlocked(_currentUserId, widget.receiverId);
    if (mounted) {
      setState(() {
        _isUserBlocked = blocked;
      });
    }
  }

  Future<void> _loadOtherUserStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        final isOnline = data['isOnline'] ?? false;
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final nickname = data['nickname'] as String?;
        final displayName = data['displayName'] as String?;

        bool actuallyOnline = false;
        if (isOnline && lastSeen != null) {
          final difference = DateTime.now().difference(lastSeen);
          actuallyOnline = difference.inMinutes < 5;
        }

        setState(() {
          _isOtherUserOnline = actuallyOnline;
          _otherUserLastSeen = lastSeen;
          _otherUserNickname =
              nickname?.isNotEmpty == true ? nickname : displayName;
        });
      }
    } catch (e) {
      print('Error loading user status: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Check if receiver has blocked the current user
    final isBlocked =
        await ChatService.isUserBlocked(widget.receiverId, _currentUserId);
    if (isBlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.block, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                    'Cannot send message - you have been blocked by this user'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
      return;
    }

    try {
      // Check if we're editing a message
      if (_editingMessage != null) {
        await _updateMessage(message.trim());
        return;
      }

      // Check if we're replying to a message
      if (_replyingTo != null) {
        await ChatService.sendReplyMessage(
          senderId: _currentUserId,
          receiverId: widget.receiverId,
          message: message.trim(),
          replyToId: _replyingTo!.id,
          replyToMessage: _replyingTo!.message,
          carPlateNumber: widget.carPlateNumber,
          carBrand: widget.carBrand,
        );
        _cancelReply();
      } else {
        // Regular message
        await ChatService.sendMessage(
          senderId: _currentUserId,
          receiverId: widget.receiverId,
          message: message.trim(),
          carPlateNumber: widget.carPlateNumber,
          carBrand: widget.carBrand,
        );
      }

      _messageController.clear();
      setState(() {
        _showQuickMessages = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'delete_conversation':
        _showDeleteConversationDialog();
        break;
      case 'report_spam':
        _showReportDialog();
        break;
      case 'block_user':
        _showBlockUserDialog();
        break;
      case 'unblock_user':
        _showUnblockUserDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    // Close keyboard before showing dialog
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.clear_all,
              color: Colors.orange[600],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Clear Chat',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete all messages in this conversation.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[600],
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.clearChat(_currentUserId, widget.receiverId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text('Chat cleared successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8.w),
                          Expanded(
                              child:
                                  Text('Error clearing chat: ${e.toString()}')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Clear Chat',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConversationDialog() {
    // Close keyboard before showing dialog
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_forever,
              color: Colors.red[600],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Delete Conversation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete the entire conversation and all messages.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.red[600],
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.deleteConversation(
                    _currentUserId, widget.receiverId);
                if (mounted) {
                  Navigator.pop(context); // Go back to chat list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text('Conversation deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: Text(
                                  'Error deleting conversation: ${e.toString()}')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Delete Conversation',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    // Close keyboard before showing dialog
    FocusScope.of(context).unfocus();

    String selectedReason = 'Spam';
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate Content',
      'Fraud',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.report,
                color: Colors.orange[600],
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Report User',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this user?',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16.h),
              ...reasons.map((reason) => Container(
                    margin: EdgeInsets.only(bottom: 4.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: selectedReason == reason
                          ? oliveColor.withOpacity(0.1)
                          : null,
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: selectedReason == reason
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedReason == reason
                              ? oliveColor
                              : Colors.black87,
                        ),
                      ),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) =>
                          setState(() => selectedReason = value!),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                      activeColor: oliveColor,
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ChatService.reportUser(
                    reporterId: _currentUserId,
                    reportedUserId: widget.receiverId,
                    reason: selectedReason,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8.w),
                            Text('User reported successfully'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 8.w),
                            Expanded(
                                child: Text(
                                    'Error reporting user: ${e.toString()}')),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Report',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.block,
              color: Colors.red[600],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Block User',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This user will no longer be able to send you messages.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[600],
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'You can unblock them later if needed',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.blockUser(_currentUserId, widget.receiverId);
                await _checkIfUserBlocked();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text('User blocked successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8.w),
                          Expanded(
                              child:
                                  Text('Error blocking user: ${e.toString()}')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Block User',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          const Color(0xFFF5F5F5), // Light gray background for better contrast
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: oliveColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: oliveColor,
                    size: 18.sp,
                  ),
                ),
                // Online status indicator next to avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color:
                          _isOtherUserOnline ? Colors.green : Colors.grey[400],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserNickname ?? widget.carBrand ?? 'Car Owner',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _isOtherUserOnline
                        ? 'Online'
                        : _otherUserLastSeen != null
                            ? 'Last seen ${_formatLastSeen(_otherUserLastSeen!)}'
                            : 'Offline',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color:
                          _isOtherUserOnline ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_chat',
                child: ListTile(
                  leading: Icon(Icons.clear_all, size: 20),
                  title: Text('Clear Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_conversation',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, size: 20),
                  title: Text('Delete Conversation'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'report_spam',
                child: ListTile(
                  leading: Icon(Icons.report, size: 20, color: Colors.orange),
                  title: Text('Report Spam/Abuse'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _isUserBlocked ? 'unblock_user' : 'block_user',
                child: ListTile(
                  leading: Icon(
                    _isUserBlocked ? Icons.person_add : Icons.block,
                    size: 20,
                    color: _isUserBlocked ? Colors.green : Colors.red,
                  ),
                  title: Text(_isUserBlocked ? 'Unblock User' : 'Block User'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Car info banner (if available)
            if (widget.carPlateNumber != null && widget.carBrand != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: oliveColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 20.sp,
                      color: oliveColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${widget.carBrand} - ${widget.carPlateNumber!.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages list
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream:
                    ChatService.getMessages(_currentUserId, widget.receiverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Color(0xFFB3B760),
                    ));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.wifi_off,
                                size: 48.sp,
                                color: Colors.orange[400],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Connection issue',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Please check your internet connection',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Trigger a rebuild to retry
                                setState(() {});
                              },
                              icon: Icon(Icons.refresh, size: 16.sp),
                              label: Text('Try again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: oliveColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return _buildEmptyChat();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16.w),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),

            // Quick messages panel
            if (_showQuickMessages) _buildQuickMessages(),

            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: oliveColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64.sp,
                    color: oliveColor,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Send your first message to begin chatting',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: oliveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: oliveColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 16.sp,
                        color: oliveColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Be respectful and helpful',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: oliveColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) SizedBox(width: 48.w),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, isMe),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? oliveColor : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show reply indicator if this is a reply
                    if (message.replyToId != null)
                      _buildReplyIndicator(message),
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (message.isEdited) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
      child: Text(
        message.replyToMessage ?? 'Original message',
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.white.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showMessageOptions(ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message.message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessages() {
    final quickMessages = ChatService.getQuickMessages();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Messages',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showQuickMessages = false;
                  });
                },
                icon: Icon(
                  Icons.close,
                  size: 18.sp,
                  color: Colors.grey.shade600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: quickMessages.map((message) {
              return InkWell(
                onTap: () => _sendMessage(message),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: oliveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: oliveColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: oliveColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply/Edit indicator
          if (_replyingTo != null || _editingMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border(
                  left: BorderSide(
                    color: _editingMessage != null ? Colors.orange : oliveColor,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit : Icons.reply,
                    size: 18.sp,
                    color: _editingMessage != null ? Colors.orange : oliveColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingMessage != null
                              ? 'Editing message'
                              : 'Replying to',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _editingMessage != null
                                ? Colors.orange
                                : oliveColor,
                          ),
                        ),
                        Text(
                          _editingMessage?.message ??
                              _replyingTo?.message ??
                              '',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_editingMessage != null) {
                        _cancelEdit();
                      } else {
                        _cancelReply();
                      }
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Main input row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick messages button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showQuickMessages = !_showQuickMessages;
                    });
                  },
                  icon: Icon(
                    Icons.flash_on,
                    color:
                        _showQuickMessages ? oliveColor : Colors.grey.shade600,
                  ),
                ),

                SizedBox(width: 8.w),

                // Text input
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 120.h, // Limit height to prevent overflow
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: oliveColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Send button
                Container(
                  decoration: const BoxDecoration(
                    color: oliveColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'yesterday';
      } else {
        return '${difference.inDays} days ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  // Reply functionality
  ChatMessage? _replyingTo;

  void _replyToMessage(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  // Edit functionality
  ChatMessage? _editingMessage;

  void _editMessage(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.message;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _updateMessage(String newMessage) async {
    if (_editingMessage == null || newMessage.trim().isEmpty) return;

    try {
      await ChatService.editMessage(_editingMessage!.id, newMessage.trim());
      _cancelEdit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete functionality
  void _deleteMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.deleteMessage(message.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting message: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Copy functionality
  void _copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showUnblockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.green[600],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Unblock User',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This user will be able to send you messages again.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green[600],
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'They will be notified that you are available for messaging',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.unblockUser(
                    _currentUserId, widget.receiverId);
                await _checkIfUserBlocked();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text('User unblocked successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: Text(
                                  'Error unblocking user: ${e.toString()}')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Unblock User',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
