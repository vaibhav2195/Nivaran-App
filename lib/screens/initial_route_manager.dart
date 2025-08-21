import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialRouteManager extends StatefulWidget {
  const InitialRouteManager({super.key});

  @override
  State<InitialRouteManager> createState() => _InitialRouteManagerState();
}

class _InitialRouteManagerState extends State<InitialRouteManager> {
  @override
  void initState() {
    super.initState();
    _checkLocaleAndNavigate();
  }

  Future<void> _checkLocaleAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale');

    if (mounted) {
      if (savedLocale != null && savedLocale.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/initial_auth_check');
      } else {
        Navigator.pushReplacementNamed(context, '/language_selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}