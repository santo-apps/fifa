import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorite Teams
  static List<String> getFavoriteTeams() {
    return _prefs.getStringList('favorite_teams') ?? [];
  }

  static Future<void> saveFavoriteTeams(List<String> teams) async {
    await _prefs.setStringList('favorite_teams', teams);
  }

  // Bookmarked Matches
  static List<String> getBookmarkedMatches() {
    return _prefs.getStringList('bookmarked_matches') ?? [];
  }

  static Future<void> saveBookmarkedMatches(List<String> matchIds) async {
    await _prefs.setStringList('bookmarked_matches', matchIds);
  }

  // Theme Settings
  static bool isDarkMode() {
    return _prefs.getBool('is_dark_mode') ?? true; // Default to dark mode for rich aesthetics
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('is_dark_mode', value);
  }

  // Notifications Toggle
  static bool areNotificationsEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool('notifications_enabled', value);
  }

  // Simulated Matches Cache (JSON string)
  static String? getSimulatedMatchesJson() {
    return _prefs.getString('simulated_matches_json');
  }

  static Future<void> saveSimulatedMatchesJson(String json) async {
    await _prefs.setString('simulated_matches_json', json);
  }

  static Future<void> clearSimulatedMatches() async {
    await _prefs.remove('simulated_matches_json');
  }
}
