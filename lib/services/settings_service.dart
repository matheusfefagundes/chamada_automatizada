import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/app_settings.dart';

class SettingsService with ChangeNotifier {
  final SharedPreferences _prefs;
  static const _studentKey = 'student_profile';
  static const _settingsKey = 'app_settings';

  Student? _student;
  AppSettings _settings = AppSettings();

  SettingsService(this._prefs) {
    _loadStudent();
    _loadSettings();
  }

  Student? getStudent() => _student;
  AppSettings getSettings() => _settings;

  void _loadStudent() {
    final studentJson = _prefs.getString(_studentKey);
    if (studentJson != null) {
      _student = Student.fromJson(json.decode(studentJson));
      notifyListeners();
    }
  }

  Future<void> saveStudent(Student student) async {
    _student = student;
    await _prefs.setString(_studentKey, json.encode(student.toJson()));
    notifyListeners();
  }

  void _loadSettings() {
    final settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson != null) {
      _settings = AppSettings.fromJson(json.decode(settingsJson));
    }
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    await _prefs.setString(_settingsKey, json.encode(settings.toJson()));
    notifyListeners();
  }
}