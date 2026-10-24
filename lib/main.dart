import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'models/user_settings.dart';
import 'services/settings_service.dart';
import 'views/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings = await SettingsService.loadSettings();
  runApp(FreeDataDietApp(initialSettings: initialSettings));
}

/// Root application widget for FreeDataDiet Mobile.
class FreeDataDietApp extends StatefulWidget {
  final UserSettings initialSettings;

  const FreeDataDietApp({super.key, required this.initialSettings});

  @override
  State<FreeDataDietApp> createState() => _FreeDataDietAppState();
}

class _FreeDataDietAppState extends State<FreeDataDietApp> {
  late UserSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _onSettingsChanged(UserSettings updated) {
    setState(() {
      _settings = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings.themeMode,
      home: MainScreen(
        settings: _settings,
        onSettingsChanged: _onSettingsChanged,
      ),
    );
  }
}
