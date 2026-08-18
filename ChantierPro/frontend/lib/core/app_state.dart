import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');
  String _currency = 'EUR'; // EUR | MRU | USD

  // Profile photo URL (network) or local path indicator
  String? _profilePhotoUrl;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get currency => _currency;

  /// Symbole affiché pour la devise choisie.
  String get currencySymbol {
    switch (_currency) {
      case 'MRU':
        return 'UM';
      case 'USD':
        return '\$';
      default:
        return '€';
    }
  }

  bool get isDark => _themeMode == ThemeMode.dark;
  String? get profilePhotoUrl => _profilePhotoUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final lang = prefs.getString('lang') ?? 'fr';
    _currency = prefs.getString('currency') ?? 'EUR';
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(lang);
    _profilePhotoUrl = prefs.getString('profilePhotoUrl');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', locale.languageCode);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  Future<void> setProfilePhoto(String url) async {
    _profilePhotoUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePhotoUrl', url);
    notifyListeners();
  }
}
