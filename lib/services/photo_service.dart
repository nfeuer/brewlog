import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for handling photo capture, storage, and management
/// Handles both local storage (free users) and Firebase Storage (paid users)
class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  // Maximum image dimensions
  static const int maxWidth = 1024;
  static const int maxHeight = 1024;
  static const int jpegQuality = 85;

  // Singleton pattern
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  /// Get the app's photo directory
  Future<Directory> _getPhotoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/photos');

    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    return photoDir;
  }

  /// Take photo with camera
  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: jpegQuality,
      );

      if (photo == null) return null;

      return await _savePhoto(photo.path);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  Future<String?> pickPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: jpegQuality,
      );

      if (photo == null) return null;

      return await _savePhoto(photo.path);
    } catch (e) {
      print('Error picking photo: $e');
      return null;
    }
  }

  /// Pick multiple photos from gallery
  Future<List<String>> pickMultiplePhotos() async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: jpegQuality,
      );

      final List<String> savedPaths = [];
      for (final photo in photos) {
        final path = await _savePhoto(photo.path);
        if (path != null) {
          savedPaths.add(path);
        }
      }

      return savedPaths;
    } catch (e) {
      print('Error picking multiple photos: $e');
      return [];
    }
  }

  /// Save and compress photo to app directory
  Future<String?> _savePhoto(String sourcePath) async {
    try {
      // Read the image
      final bytes = await File(sourcePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height >= image.width ? maxHeight : null,
        );
      }

      // Compress to JPEG
      final compressed = img.encodeJpg(resized, quality: jpegQuality);

      // Save to app directory
      final photoDir = await _getPhotoDirectory();
      final filename = '${_uuid.v4()}.jpg';
      final savedFile = File('${photoDir.path}/$filename');
      await savedFile.writeAsBytes(compressed);

      return savedFile.path;
    } catch (e) {
      print('Error saving photo: $e');
      return null;
    }
  }

  /// Delete photo from local storage
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Delete multiple photos
  Future<void> deletePhotos(List<String> photoPaths) async {
    for (final path in photoPaths) {
      await deletePhoto(path);
    }
  }

  /// Get file from path (for display)
  File? getPhotoFile(String photoPath) {
    try {
      final file = File(photoPath);
      return file;
    } catch (e) {
      print('Error getting photo file: $e');
      return null;
    }
  }

  /// Check if photo exists
  Future<bool> photoExists(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get photo size in bytes
  Future<int?> getPhotoSize(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      print('Error getting photo size: $e');
      return null;
    }
  }

  /// Get total size of all photos
  Future<int> getTotalPhotosSize() async {
    try {
      final photoDir = await _getPhotoDirectory();
      int totalSize = 0;

      await for (final entity in photoDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('Error calculating total photos size: $e');
      return 0;
    }
  }

  /// Clean up orphaned photos (photos not referenced by any cup)
  Future<int> cleanupOrphanedPhotos(List<String> referencedPaths) async {
    try {
      final photoDir = await _getPhotoDirectory();
      int deletedCount = 0;

      await for (final entity in photoDir.list()) {
        if (entity is File) {
          final path = entity.path;
          if (!referencedPaths.contains(path)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up orphaned photos: $e');
      return 0;
    }
  }

  /// Copy photo (for duplicating cups)
  Future<String?> copyPhoto(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      if (!await originalFile.exists()) return null;

      final photoDir = await _getPhotoDirectory();
      final filename = '${_uuid.v4()}.jpg';
      final newFile = File('${photoDir.path}/$filename');

      await originalFile.copy(newFile.path);
      return newFile.path;
    } catch (e) {
      print('Error copying photo: $e');
      return null;
    }
  }

  // ============================================================================
  // FIREBASE STORAGE METHODS (For Paid Users)
  // ============================================================================
  // These methods will be implemented when Firebase is configured

  /// Upload photo to Firebase Storage
  /// Returns the download URL if successful
  Future<String?> uploadToFirebase(String localPath, String userId) async {
    // TODO: Implement Firebase Storage upload
    // Example implementation:
    /*
    try {
      final file = File(localPath);
      final filename = path.basename(localPath);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/photos/$filename');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading to Firebase: $e');
      return null;
    }
    */

    print('Firebase upload not yet implemented');
    return null;
  }

  /// Download photo from Firebase Storage
  /// Returns the local path if successful
  Future<String?> downloadFromFirebase(String firebaseUrl) async {
    // TODO: Implement Firebase Storage download
    // Example implementation:
    /*
    try {
      final ref = FirebaseStorage.instance.refFromURL(firebaseUrl);
      final photoDir = await _getPhotoDirectory();
      final filename = '${_uuid.v4()}.jpg';
      final localFile = File('${photoDir.path}/$filename');

      await ref.writeToFile(localFile);
      return localFile.path;
    } catch (e) {
      print('Error downloading from Firebase: $e');
      return null;
    }
    */

    print('Firebase download not yet implemented');
    return null;
  }

  /// Sync local photos to Firebase for paid user
  Future<Map<String, String>> syncPhotosToFirebase(
    List<String> localPaths,
    String userId,
  ) async {
    final Map<String, String> urlMap = {}; // localPath -> firebaseUrl

    for (final localPath in localPaths) {
      final url = await uploadToFirebase(localPath, userId);
      if (url != null) {
        urlMap[localPath] = url;
      }
    }

    return urlMap;
  }
}
