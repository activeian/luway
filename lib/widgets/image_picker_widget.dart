import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/image_upload_service.dart';

const Color oliveColor = Color(0xFF808000);

class ImagePickerWidget extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final String title;
  final bool enabled;

  const ImagePickerWidget({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
    this.maxImages = 10,
    this.title = 'Images',
    this.enabled = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  List<String> _images = [];
  List<XFile> _pendingImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      setState(() {
        _images = List.from(widget.initialImages);
      });
    }
  }

  Future<void> _pickImages() async {
    if (!widget.enabled || _isUploading) return;

    try {
      final remainingSlots = widget.maxImages - _images.length;
      if (remainingSlots <= 0) {
        _showSnackBar('Maximum ${widget.maxImages} images allowed');
        return;
      }

      final pickedImages = await ImageUploadService.pickImages(
        allowMultiple: true,
        maxImages: remainingSlots,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          _pendingImages = pickedImages;
          _isUploading = true;
        });

        try {
          final uploadedUrls =
              await ImageUploadService.uploadImages(pickedImages);

          setState(() {
            _images.addAll(uploadedUrls);
            _pendingImages.clear();
            _isUploading = false;
          });

          widget.onImagesChanged(_images);
          _showSnackBar('${uploadedUrls.length} images uploaded successfully',
              isSuccess: true);
        } catch (e) {
          setState(() {
            _pendingImages.clear();
            _isUploading = false;
          });
          _showSnackBar('Upload failed: $e');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick images: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (!widget.enabled || _isUploading) return;

    try {
      if (_images.length >= widget.maxImages) {
        _showSnackBar('Maximum ${widget.maxImages} images allowed');
        return;
      }

      final pickedImages = await ImageUploadService.pickImages(
        allowMultiple: false,
        source: ImageSource.camera,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          _pendingImages = pickedImages;
          _isUploading = true;
        });

        try {
          final uploadedUrls =
              await ImageUploadService.uploadImages(pickedImages);

          setState(() {
            _images.addAll(uploadedUrls);
            _pendingImages.clear();
            _isUploading = false;
          });

          widget.onImagesChanged(_images);
          _showSnackBar('Photo uploaded successfully', isSuccess: true);
        } catch (e) {
          setState(() {
            _pendingImages.clear();
            _isUploading = false;
          });
          _showSnackBar('Upload failed: $e');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to take photo: $e');
    }
  }

  void _removeImage(int index) {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Images',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages();
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: oliveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: oliveColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: oliveColor,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: oliveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _images.length + _pendingImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '(${_images.length}/${widget.maxImages})',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            if (widget.enabled && totalImages < widget.maxImages)
              TextButton.icon(
                onPressed: _isUploading ? null : _showImageOptions,
                icon: Icon(
                  Icons.add_a_photo,
                  size: 16.sp,
                  color: _isUploading ? Colors.grey : oliveColor,
                ),
                label: Text(
                  'Add Images',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _isUploading ? Colors.grey : oliveColor,
                  ),
                ),
              ),
          ],
        ),
        if (_images.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'Long press and drag to reorder images',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        SizedBox(height: 12.h),
        if (_images.isEmpty && _pendingImages.isEmpty)
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 32.sp,
                  color: Colors.grey.shade500,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Add up to ${widget.maxImages} images',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            constraints: BoxConstraints(minHeight: 120.h),
            child: Column(
              children: [
                // Uploaded images
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _images.asMap().entries.map((entry) {
                      int index = entry.key;
                      String imageUrl = entry.value;
                      return _buildImageTile(imageUrl, index);
                    }).toList(),
                  ),

                // Pending images
                if (_pendingImages.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: _images.isNotEmpty ? 8.h : 0),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _pendingImages.map((imageFile) {
                        return _buildPendingImageTile(imageFile);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        if (_isUploading)
          Container(
            margin: EdgeInsets.only(top: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: oliveColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(oliveColor),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Uploading ${_pendingImages.length} image(s)...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: oliveColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(String imageUrl, int index) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Container(
        width: (MediaQuery.of(context).size.width - 48.w) / 3,
        height: (MediaQuery.of(context).size.width - 48.w) / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: (MediaQuery.of(context).size.width - 48.w) / 3,
        height: (MediaQuery.of(context).size.width - 48.w) / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          color: Colors.grey.shade100,
        ),
        child: Icon(
          Icons.drag_indicator,
          color: Colors.grey.shade400,
        ),
      ),
      child: DragTarget<int>(
        onAccept: (draggedIndex) {
          if (draggedIndex != index) {
            setState(() {
              final item = _images.removeAt(draggedIndex);
              _images.insert(index, item);
            });
            widget.onImagesChanged(_images);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: (MediaQuery.of(context).size.width - 48.w) / 3,
            height: (MediaQuery.of(context).size.width - 48.w) / 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? const Color(0xFFB3B760)
                    : Colors.grey.shade300,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(oliveColor),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade500,
                            size: 24.sp,
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.enabled && !_isUploading)
                    Positioned(
                      top: 4.w,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Drag indicator
                  Positioned(
                    bottom: 4.w,
                    right: 4.w,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingImageTile(XFile imageFile) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48.w) / 3,
      height: (MediaQuery.of(context).size.width - 48.w) / 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.file(
                File(imageFile.path),
                fit: BoxFit.cover,
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
