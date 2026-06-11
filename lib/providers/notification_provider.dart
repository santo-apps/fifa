import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import '../data/models/match_model.dart';

class NotificationProvider extends ChangeNotifier {
  bool _enabled = true;
  List<String> _reminderMatchIds = [];

  NotificationProvider() {
    _enabled = StorageService.areNotificationsEnabled();
    _reminderMatchIds = StorageService.getBookmarkedMatches(); // Default to bookmarks or separate list
  }

  bool get enabled => _enabled;
  List<String> get reminderMatchIds => _reminderMatchIds;

  bool hasReminder(String matchId) {
    return _reminderMatchIds.contains(matchId);
  }

  Future<void> toggleGlobalNotifications(bool value) async {
    _enabled = value;
    await StorageService.setNotificationsEnabled(_enabled);
    if (!_enabled) {
      await NotificationService.cancelAllNotifications();
    }
    notifyListeners();
  }

  Future<void> toggleReminder(MatchModel match) async {
    if (_reminderMatchIds.contains(match.id)) {
      _reminderMatchIds.remove(match.id);
      await NotificationService.cancelNotification(match.matchNumber);
    } else {
      _reminderMatchIds.add(match.id);
      if (_enabled) {
        // Schedule reminder 15 minutes before match kickoff
        await NotificationService.scheduleMatchReminder(
          id: match.matchNumber,
          title: 'Upcoming Kickoff: ${match.homeTeam} vs ${match.awayTeam}',
          body: 'Kickoff in 15 minutes at ${match.venue}, ${match.city}. Keep track of live updates!',
          scheduledTime: match.dateTime,
        );
      }
    }
    notifyListeners();
  }

  // Helper to trigger instant notifications for simulator testing
  Future<void> triggerInstantMatchAlert(MatchModel match, String title, String body) async {
    if (_enabled) {
      await NotificationService.showInstantNotification(
        id: match.matchNumber + 1000, // Unique simulator notification offset
        title: title,
        body: body,
      );
    }
  }
}
