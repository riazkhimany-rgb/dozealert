import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'services/settings_service.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const DozeAlertApp());
}

class DozeAlertApp extends StatelessWidget {
  const DozeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DozeAlert',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
