import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static const String _uploadUrl = 'https://wzsgame.com/upload.php';
  static const int _maxImages = 10;
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int _compressionQuality = 20; // Reduce to 20% of original size for 70-80% compression

  /// Upload multiple images with compression
  static Future<List<String>> uploadImages(List<XFile> images) async {
    if (images.isEmpty) {
      throw Exception('No images to upload');
    }

    if (images.length > _maxImages) {
      throw Exception('Maximum $_maxImages images allowed');
    }

    try {
      if (kDebugMode) {
        print('Starting image upload process...');
        print('Number of images: ${images.length}');
        print('Upload URL: $_uploadUrl');
      }
      
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        
        // Read image bytes
        final bytes = await image.readAsBytes();
        
        // Check file size
        if (bytes.length > _maxFileSize) {
          throw Exception('Image ${i + 1} is too large. Maximum 5MB allowed.');
        }

        // Compress image
        final compressedBytes = await _compressImage(bytes);
        
        // Add to request with array-style field name for PHP
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[]', // Use array notation for PHP
            compressedBytes,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (kDebugMode) {
        print('Server response status: ${response.statusCode}');
        print('Server response headers: ${response.headers}');
        print('Server response data: $responseData');
        print('Request URL: $_uploadUrl');
        print('Number of files: ${images.length}');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}: $responseData');
      }
      
      if (responseData.isEmpty) {
        throw Exception('Empty response from server');
      }
      
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['success'] == true) {
        return List<String>.from(jsonResponse['urls'] ?? []);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image upload error: $e');
      }
      throw Exception('Failed to upload images: $e');
    }
  }

  /// Compress image to reduce file size by 70-80%
  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Decode the image
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions (reduce by ~30-40% for size reduction)
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;
      
      // If image is too large, resize it
      const maxDimension = 1200;
      if (newWidth > maxDimension || newHeight > maxDimension) {
        if (newWidth > newHeight) {
          newHeight = (newHeight * maxDimension / newWidth).round();
          newWidth = maxDimension;
        } else {
          newWidth = (newWidth * maxDimension / newHeight).round();
          newHeight = maxDimension;
        }
      }

      // Resize image if dimensions changed
      img.Image resizedImage = originalImage;
      if (newWidth != originalImage.width || newHeight != originalImage.height) {
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with compression
      final compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _compressionQuality,
      );

      if (kDebugMode) {
        print('Original size: ${bytes.length} bytes');
        print('Compressed size: ${compressedBytes.length} bytes');
        print('Compression ratio: ${((1 - compressedBytes.length / bytes.length) * 100).toStringAsFixed(1)}%');
      }

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Image compression error: $e');
      }
      // If compression fails, return original bytes
      return bytes;
    }
  }

  /// Pick images from gallery or camera
  static Future<List<XFile>> pickImages({
    bool allowMultiple = true,
    int maxImages = 10,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picker = ImagePicker();
    
    try {
      if (allowMultiple && source == ImageSource.gallery) {
        final images = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        
        if (images.length > maxImages) {
          return images.take(maxImages).toList();
        }
        
        return images;
      } else {
        final image = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        
        return image != null ? [image] : [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image picker error: $e');
      }
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Delete image from server (if needed)
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.last;
      
      // This would require a separate delete endpoint on your server
      // For now, we'll just return true
      if (kDebugMode) {
        print('Would delete image: $filename');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Delete image error: $e');
      }
      return false;
    }
  }

  /// Validate image file
  static bool isValidImage(XFile file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Test upload connectivity
  static Future<Map<String, dynamic>> testUpload() async {
    try {
      final response = await http.get(Uri.parse(_uploadUrl.replaceAll('upload.php', '')));
      return {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'Server is reachable',
        'headers': response.headers.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Cannot reach server',
      };
    }
  }
}
