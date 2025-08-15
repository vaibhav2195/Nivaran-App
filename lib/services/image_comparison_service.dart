import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as developer;

class ImageComparisonService {
  // Threshold for considering images similar (0.0 to 1.0)
  // Higher values require more similarity
  static const double _similarityThreshold = 0.75;
  
  // Image size for comparison (smaller = faster but less accurate)
  static const int _comparisonImageSize = 32;

  /// Compares two images and returns a similarity score between 0.0 and 1.0
  /// Higher values indicate more similarity
  static Future<double> compareImages(File image1, File image2) async {
    try {
      return await compute(_compareImagesIsolate, [image1.path, image2.path]);
    } catch (e) {
      developer.log('Error comparing images: ${e.toString()}', name: 'ImageComparisonService');
      return 0.0;
    }
  }

  /// Compares a list of image files with another list and returns the highest similarity score
  static Future<double> compareImageSets(List<File> images1, List<File> images2) async {
    if (images1.isEmpty || images2.isEmpty) {
      return 0.0;
    }

    double highestSimilarity = 0.0;

    // Compare each image from the first set with each image from the second set
    for (final img1 in images1) {
      for (final img2 in images2) {
        final similarity = await compareImages(img1, img2);
        if (similarity > highestSimilarity) {
          highestSimilarity = similarity;
        }

        // Early exit if we found a very similar image
        if (highestSimilarity >= _similarityThreshold) {
          return highestSimilarity;
        }
      }
    }

    return highestSimilarity;
  }

  /// Determines if two sets of images are likely duplicates based on similarity
  static Future<bool> areImageSetsDuplicates(List<File> images1, List<File> images2) async {
    final similarity = await compareImageSets(images1, images2);
    return similarity >= _similarityThreshold;
  }

  /// Compares two images by path and returns a similarity score
  /// This runs in an isolate for better performance
  static Future<double> _compareImagesIsolate(List<String> imagePaths) async {
    try {
      final image1 = await _loadAndResizeImage(imagePaths[0]);
      final image2 = await _loadAndResizeImage(imagePaths[1]);

      if (image1 == null || image2 == null) {
        return 0.0;
      }

      // Calculate perceptual hash (pHash) for both images
      final hash1 = _calculatePerceptualHash(image1);
      final hash2 = _calculatePerceptualHash(image2);

      // Calculate Hamming distance between hashes
      final distance = _hammingDistance(hash1, hash2);

      // Convert distance to similarity score (0.0 to 1.0)
      // 64 is the maximum possible distance for 64-bit hashes
      return 1.0 - (distance / 64.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Loads and resizes an image for comparison
  static Future<img.Image?> _loadAndResizeImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // Resize image to standard size for comparison
      return img.copyResize(
        image,
        width: _comparisonImageSize,
        height: _comparisonImageSize,
        interpolation: img.Interpolation.average,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculates a perceptual hash (pHash) for an image
  /// Returns a 64-bit hash as a List of bool values
  static List<bool> _calculatePerceptualHash(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);

    // Calculate the average pixel value
    int sum = 0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        // Access the blue channel value from the pixel
        sum += pixel.b.toInt(); // In grayscale, R=G=B
      }    
    }
    final avg = (sum / (grayscale.width * grayscale.height)).round();

    // Generate the hash based on whether pixel is above or below average
    final List<bool> hash = [];
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        if (hash.length >= 64) break; // Ensure we only get 64 bits
        final pixel = grayscale.getPixel(x, y);
        hash.add(pixel.b > avg);
      }
    }

    // Pad or truncate to exactly 64 bits
    while (hash.length < 64) {
      hash.add(false);
    }

    return hash.sublist(0, 64);
  }

  /// Calculates the Hamming distance between two binary hashes
  /// (number of positions at which the bits differ)
  static int _hammingDistance(List<bool> hash1, List<bool> hash2) {
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        distance++;
      }
    }
    return distance;
  }
}