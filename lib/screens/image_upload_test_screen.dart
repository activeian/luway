import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadTestScreen extends StatefulWidget {
  const ImageUploadTestScreen({Key? key}) : super(key: key);

  @override
  State<ImageUploadTestScreen> createState() => _ImageUploadTestScreenState();
}

class _ImageUploadTestScreenState extends State<ImageUploadTestScreen> {
  bool _isUploading = false;
  String _statusMessage = '';
  List<String> _uploadedUrls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Test'),
        backgroundColor: const Color(0xFF8FBC8F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isUploading ? null : _testServerConnection,
              child: const Text('Test Server Connection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadSingleImage,
              child: const Text('Pick & Upload Single Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadMultipleImages,
              child: const Text('Pick & Upload Multiple Images'),
            ),
            const SizedBox(height: 24),
            if (_isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Uploading...'),
                  ],
                ),
              ),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  border: Border.all(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                        ? Colors.red
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_uploadedUrls.isNotEmpty) ...[
              const Text(
                'Uploaded Images:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _uploadedUrls.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          _uploadedUrls[index],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                        title: Text('Image ${index + 1}'),
                        subtitle: Text(_uploadedUrls[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Copy URL to clipboard (implement if needed)
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Testing server connection...';
    });

    try {
      final result = await ImageUploadService.testUpload();
      setState(() {
        _statusMessage = 'Server Test Result:\n'
            'Success: ${result['success']}\n'
            'Status Code: ${result['statusCode']}\n'
            'Message: ${result['message']}\n'
            'Error: ${result['error'] ?? 'None'}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Server Test Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickAndUploadSingleImage() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Picking image...';
      _uploadedUrls.clear();
    });

    try {
      final images = await ImageUploadService.pickImages(
        allowMultiple: false,
        source: ImageSource.gallery,
      );

      if (images.isEmpty) {
        setState(() {
          _statusMessage = 'No image selected';
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Uploading image...';
      });

      final urls = await ImageUploadService.uploadImages(images);
      
      setState(() {
        _uploadedUrls = urls;
        _statusMessage = 'Successfully uploaded ${urls.length} image(s)!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload Error: $e';
      });
      
      if (kDebugMode) {
        print('Upload error details: $e');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickAndUploadMultipleImages() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Picking images...';
      _uploadedUrls.clear();
    });

    try {
      final images = await ImageUploadService.pickImages(
        allowMultiple: true,
        maxImages: 5, // Test with fewer images first
        source: ImageSource.gallery,
      );

      if (images.isEmpty) {
        setState(() {
          _statusMessage = 'No images selected';
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Uploading ${images.length} images...';
      });

      final urls = await ImageUploadService.uploadImages(images);
      
      setState(() {
        _uploadedUrls = urls;
        _statusMessage = 'Successfully uploaded ${urls.length} image(s) out of ${images.length} selected!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload Error: $e';
      });
      
      if (kDebugMode) {
        print('Upload error details: $e');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
