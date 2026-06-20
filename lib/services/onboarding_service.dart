import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completeKey = 'onboarding_complete';
  static const _alarmTestedKey = 'onboarding_alarm_tested';

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completeKey) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completeKey, true);
  }

  Future<bool> isAlarmTested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmTestedKey) ?? false;
  }

  Future<void> markAlarmTested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmTestedKey, true);
  }

  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completeKey);
    await prefs.remove(_alarmTestedKey);
  }
}
