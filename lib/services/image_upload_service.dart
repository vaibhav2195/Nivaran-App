// lib/services/image_upload_service.dart
import 'dart:io';
//import 'dart:convert';
// Firebase imports (commented out but kept for future reference)
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // For generating unique filenames
import 'dart:developer' as developer;
import 'package:cloudinary_public/cloudinary_public.dart';
import '../secrets.dart';

class ImageUploadService {
  // Firebase Storage fields (commented out but kept for future reference)
  // final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instanceFor(
  //   bucket: 'mitram-ee2ee'
  // );
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cloudinary implementation
  final CloudinaryPublic _cloudinary;
  final Uuid _uuid = const Uuid();
  
  ImageUploadService()
      : _cloudinary = CloudinaryPublic(
          cloudinaryCloudName,
          cloudinaryUploadPreset,
        ) {
    developer.log('Cloudinary initialized with cloud name: $cloudinaryCloudName',
                 name: 'ImageUploadService');
  }

  // Firebase Storage implementation (commented out but kept for future reference)
  // Future<String?> uploadImage(File imageFile) async {
  //   final User? currentUser = _auth.currentUser;
  //   if (currentUser == null) {
  //     developer.log('User not authenticated, cannot upload image.', name: 'ImageUploadService');
  //     throw Exception('User not authenticated. Cannot upload image.');
  //   }
  //
  //   try {
  //     // Generate a unique filename to avoid overwrites and ensure privacy if needed
  //     final String fileExtension = imageFile.path.split('.').last;
  //     final String fileName = '${_uuid.v4()}.$fileExtension';
  //     
  //     // Define the path in Firebase Storage.
  //     // As per requirement, storing images directly at the root of the bucket
  //     // without creating any subfolders
  //     final String filePath = fileName;
  //     
  //     // No need to check for directory existence when uploading to root
  //     
  //     firebase_storage.Reference ref = _storage.ref().child(filePath);
  //
  //     developer.log('Uploading image to Firebase Storage at path: $filePath', name: 'ImageUploadService');
  //
  //     // Upload the file
  //     firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
  //
  //     // Wait for the upload to complete
  //     firebase_storage.TaskSnapshot snapshot = await uploadTask;
  //
  //     // Get the download URL
  //     final String downloadUrl = await snapshot.ref.getDownloadURL();
  //     
  //     developer.log('Image uploaded successfully. Download URL: $downloadUrl', name: 'ImageUploadService');
  //     return downloadUrl;
  //
  //   } on firebase_storage.FirebaseException catch (e) {
  //     developer.log('Firebase Storage Error: ${e.code} - ${e.message}', name: 'ImageUploadService', error: e);
  //     // Handle specific Firebase Storage errors
  //     // e.g., e.code == 'object-not-found', 'unauthorized', 'canceled', etc.
  //     throw Exception('Failed to upload image to Firebase Storage. Error: ${e.message}');
  //   } catch (e, s) {
  //     developer.log('Upload Image Exception: $e', name: 'ImageUploadService', error: e, stackTrace: s);
  //     // Return null or rethrow a custom exception
  //     return null; 
  //   }
  // }
  
  // Cloudinary implementation
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Generate a unique filename to avoid overwrites
      final String fileExtension = imageFile.path.split('.').last;
      final String fileName = '${_uuid.v4()}.$fileExtension';
      
      developer.log('Uploading image to Cloudinary with filename: $fileName', name: 'ImageUploadService');
      
      // Create CloudinaryResponse by uploading the file
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'nivaran', // Optional: organize images in a folder
        ),
      );
      
      // Get the secure URL from the response
      final String secureUrl = response.secureUrl;
      
      developer.log('Image uploaded successfully to Cloudinary. URL: $secureUrl', name: 'ImageUploadService');
      return secureUrl;
      
    } on CloudinaryException catch (e) {
      developer.log('Cloudinary Error: ${e.message}', name: 'ImageUploadService', error: e);
      throw Exception('Failed to upload image to Cloudinary. Error: ${e.message}');
    } catch (e, s) {
      developer.log('Upload Image Exception: $e', name: 'ImageUploadService', error: e, stackTrace: s);
      // Return null or rethrow a custom exception
      return null;
    }
  }
}
