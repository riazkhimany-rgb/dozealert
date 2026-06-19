import '../models/app_settings.dart';

class SettingsService {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}
