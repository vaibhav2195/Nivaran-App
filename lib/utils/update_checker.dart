import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

// Replace this with your real RSA public key in PEM format
const String updatePublicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1QwIDAQAB
-----END PUBLIC KEY-----''';

bool verifySignature(String message, String signatureBase64, String publicKeyPem) {
  try {
    final lines = publicKeyPem.split('\n');
    final keyData = lines.sublist(1, lines.length - 2).join('');
    final publicKeyBytes = base64.decode(keyData);
    final asn1Parser = pc.ASN1Parser(publicKeyBytes);
    final topLevelSeq = asn1Parser.nextObject() as pc.ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1] as pc.ASN1BitString;
    final publicKeyAsn = pc.ASN1Parser(publicKeyBitString.contentBytes());
    final publicKeySeq = publicKeyAsn.nextObject() as pc.ASN1Sequence;
    final modulus = (publicKeySeq.elements[0] as pc.ASN1Integer).valueAsBigInteger;
    final exponent = (publicKeySeq.elements[1] as pc.ASN1Integer).valueAsBigInteger;
    final rsaPublicKey = pc.RSAPublicKey(modulus, exponent);
    final signer = pc.Signer('SHA-256/RSA');
    final pubParams = pc.PublicKeyParameter<pc.RSAPublicKey>(rsaPublicKey);
    signer.init(false, pubParams);
    final sigBytes = base64.decode(signatureBase64);
    return signer.verifySignature(
      Uint8List.fromList(utf8.encode(message)),
      pc.RSASignature(sigBytes),
    );
  } catch (e) {
    return false;
  }
}

class UpdateChecker {
  static const String versionUrl = 'https://versionhost-88b2d.web.app/version.json';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'];
        final apkUrl = data['apk_url'];
        final apkHash = data['apk_sha256'];
        final signature = data['signature']; // base64-encoded signature of version|apk_url|apk_sha256

        // Compose the message to verify (must match what is signed on the server)
        final message = '$latestVersion|$apkUrl|$apkHash';
        final isValid = verifySignature(message, signature, updatePublicKeyPem);
        if (!isValid) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Update Verification Failed'),
                content: const Text('The update information could not be verified. Please try again later.'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            );
          }
          return;
        }

        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(context, latestVersion, apkUrl, apkHash);
        }
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  static bool _isNewerVersion(String latestVersion, String currentVersion) {
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String apkUrl, String apkHash) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update Available'),
          content: Text('A new version ($version) is available. Would you like to update now?'),
          actions: [
            TextButton(
              child: const Text('Later'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Update Now'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _startDownload(context, apkUrl, apkHash);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _startDownload(BuildContext context, String url, String apkHash) async {
    try {
      // For Android 10 and above, we need to request storage permission differently
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isDenied) {
          final status = await Permission.manageExternalStorage.request();
          if (status.isDenied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission is required to download the update')),
              );
            }
            return;
          }
        }

        if (await Permission.requestInstallPackages.isDenied) {
          final status = await Permission.requestInstallPackages.request();
          if (status.isDenied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission to install packages is required')),
              );
            }
            return;
          }
        }

        // Check if permissions are permanently denied
        if (await Permission.manageExternalStorage.isPermanentlyDenied ||
            await Permission.requestInstallPackages.isPermanentlyDenied) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permissions Required'),
                content: const Text('Storage and installation permissions are required. Please enable them in app settings.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      final dio = Dio();
      Directory? dir;
      
      if (Platform.isAndroid) {
        // For Android 10+, use app-specific directory
        dir = await getExternalStorageDirectory();
      }
      
      dir ??= await getTemporaryDirectory();

      final savePath = '${dir.path}/app-update.apk';
      
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DownloadProgressDialog(
            dio: dio,
            url: url,
            savePath: savePath,
            apkHash: apkHash,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }
}

class DownloadProgressDialog extends StatefulWidget {
  final Dio dio;
  final String url;
  final String savePath;
  final String apkHash;

  const DownloadProgressDialog({
    super.key,
    required this.dio,
    required this.url,
    required this.savePath,
    required this.apkHash,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  bool _isDownloading = true;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.dio.download(
        widget.url,
        widget.savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      // After download, verify the APK hash
      final file = File(widget.savePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'APK file not found after download.';
          _isDownloading = false;
        });
        return;
      }
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final downloadedHash = digest.toString();
      if (downloadedHash.toLowerCase() != widget.apkHash.toLowerCase()) {
        // Delete the potentially malicious file
        await file.delete();
        setState(() {
          _error = 'Downloaded APK failed integrity check. Update aborted.';
          _isDownloading = false;
        });
        return;
      }

      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
        _openApk(widget.savePath);
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to download the update. Please check your internet connection and try again.';
        _isDownloading = false;
      });
    }
  }

  Future<void> _openApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('APK file not found')),
          );
        }
        return;
      }

      // Get package name using package_info_plus
      final packageInfo = await PackageInfo.fromPlatform();
      final uri = Uri.parse('content://${packageInfo.packageName}.provider/external_files/${file.path.split('/').last}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableDomStorage: false,
            enableJavaScript: false,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open the downloaded APK. Please install it manually.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening APK: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open the APK file. Please install it manually.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            )
          else if (_isDownloading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${(_progress * 100).toStringAsFixed(1)}%'),
          ] else
            const Text('Download Complete!'),
        ],
      ),
      actions: [
        if (_error != null || !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
