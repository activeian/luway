import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

const Color oliveColor = Color(0xFFB3B760);

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterConversations(
      List<Map<String, dynamic>> conversations) {
    if (_searchQuery.isEmpty) return conversations;

    return conversations.where((conversation) {
      final carBrand = (conversation['carBrand'] ?? '').toLowerCase();
      final carPlateNumber =
          (conversation['carPlateNumber'] ?? '').toLowerCase();
      final lastMessage = (conversation['lastMessage'] ?? '').toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return carBrand.contains(searchLower) ||
          carPlateNumber.contains(searchLower) ||
          lastMessage.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Messages',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login,
                  size: 80.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Please log in',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'You need to be logged in to view your messages',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search conversations, names, plates, messages...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 20.sp,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[500],
                          size: 20.sp,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService.getUserConversations(currentUser.uid),
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
                        size: 64.sp,
                        color: Colors.orange[400],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Connection issue',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Please check your internet connection and try again',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger a rebuild to retry
                        setState(() {});
                      },
                      icon: Icon(Icons.refresh, size: 16.sp),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3B760),
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

          final allConversations = snapshot.data ?? [];
          final filteredConversations = _filterConversations(allConversations);

          if (allConversations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3B760).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 64.sp,
                        color: const Color(0xFFB3B760),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Start a conversation by contacting a car owner',
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
                        color: const Color(0xFFB3B760).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: const Color(0xFFB3B760).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 16.sp,
                            color: const Color(0xFFB3B760),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Browse cars to start chatting',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFB3B760),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filteredConversations.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80.sp,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Try different search terms',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation = filteredConversations[index];
              return _buildConversationTile(
                  context, conversation, currentUser.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context,
      Map<String, dynamic> conversation, String currentUserId) {
    final participants = List<String>.from(conversation['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageTime = conversation['lastMessageTime']?.toDate();
    final lastMessageSenderId = conversation['lastMessageSenderId'] ?? '';
    final carPlateNumber = conversation['carPlateNumber'];
    final carBrand = conversation['carBrand'];
    final otherUserLastSeen = conversation['otherUserLastSeen']?.toDate();
    final isOnline = conversation['isOnline'] ?? false;
    final otherUserNickname = conversation['otherUserNickname'] as String?;
    final otherUserDisplayName =
        conversation['otherUserDisplayName'] as String?;

    final isUnread =
        lastMessageSenderId != currentUserId && lastMessageSenderId.isNotEmpty;

    // Use nickname if available, fallback to display name, then car brand, finally default
    final displayName = otherUserNickname?.isNotEmpty == true
        ? otherUserNickname!
        : otherUserDisplayName?.isNotEmpty == true
            ? otherUserDisplayName!
            : carBrand ?? 'Car Owner';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Stack(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: oliveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: oliveColor,
                size: 24.sp,
              ),
            ),
            // Online status indicator - positioned next to the avatar circle
            Positioned(
              bottom: 2.h,
              right: 2.w,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey[400],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUnread)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: oliveColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (carPlateNumber != null) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  carPlateNumber.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Text(
              lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            // Online status text with real-time updates
            Text(
              isOnline
                  ? 'Online'
                  : otherUserLastSeen != null
                      ? 'Last seen ${_formatLastSeen(otherUserLastSeen)}'
                      : 'Offline',
              style: TextStyle(
                fontSize: 11.sp,
                color: isOnline ? Colors.green : Colors.grey.shade400,
                fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessageTime != null)
              Text(
                _formatTime(lastMessageTime),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            SizedBox(height: 4.h),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationScreen(
                receiverId: otherUserId,
                carPlateNumber: carPlateNumber,
                carBrand: carBrand,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
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
}
