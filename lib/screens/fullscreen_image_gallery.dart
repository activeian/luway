import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenImageGallery({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: false,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 80.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Imaginea nu poate fi încărcată',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and image counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10.h,
                left: 16.w,
                right: 16.w,
                bottom: 10.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom dots indicator (only if more than one image)
          if (widget.images.length > 1)
            Positioned(
              bottom: 50.h,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      width: _currentIndex == index ? 20.w : 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Navigation arrows (for larger screens)
          if (widget.images.length > 1 &&
              MediaQuery.of(context).size.width > 600) ...[
            // Previous arrow
            Positioned(
              left: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _currentIndex > 0
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    size: 30.sp,
                  ),
                ),
              ),
            ),
            // Next arrow
            Positioned(
              right: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _currentIndex < widget.images.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: _currentIndex < widget.images.length - 1
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    size: 30.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
