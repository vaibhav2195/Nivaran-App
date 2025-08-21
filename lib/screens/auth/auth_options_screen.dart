
import 'package:flutter/material.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
//import '../../l10n/app_localizations_en.dart';
import '../../common/app_logo.dart';
import '../../widgets/auth_button.dart';

class AuthOptionsScreen extends StatelessWidget {
  final String userType; 

  const AuthOptionsScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isOfficial = userType == 'official';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppLogo(logoSymbolSize: 28, showAppName: false), 
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                 SizedBox(height: screenHeight * 0.1),
                Text(
                  AppLocalizations.of(context)!.letsGetStarted,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
                SizedBox(height: screenHeight * 0.12), 
                AuthButton(
                  text: AppLocalizations.of(context)!.login,
                  onPressed: () {
                    if (isOfficial) {
                      Navigator.pushNamed(context, '/official_login');
                    } else {
                      Navigator.pushNamed(context, '/login');
                    }
                  },
                ),
                SizedBox(height: screenHeight * 0.025),
                 Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 0.8)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          AppLocalizations.of(context)!.orContinueWith.split(' ')[0],
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 0.8)),
                    ],
                  ),
                SizedBox(height: screenHeight * 0.025),
                AuthButton(
                  text: AppLocalizations.of(context)!.signUp,
                  onPressed: () {
                    if (isOfficial) {
                      Navigator.pushNamed(context, '/official_signup');
                    } else {
                      Navigator.pushNamed(context, '/signup');
                    }
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}