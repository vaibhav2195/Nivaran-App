import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/locale_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _setLocale(BuildContext context, String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
    localeProvider.setLocale(Locale(languageCode));
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/initial_auth_check');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Your Language',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _setLocale(context, 'en'),
              child: const Text('English'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _setLocale(context, 'hi'),
              child: const Text('हिंदी'),
            ),
          ],
        ),
      ),
    );
  }
}