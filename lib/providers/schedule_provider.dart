import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/match_model.dart';
import '../data/repositories/match_repository.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import 'notification_provider.dart';

class ScheduleProvider extends ChangeNotifier {
  final MatchRepository _repository = MatchRepository();

  List<MatchModel> _matches = [];
  bool _isLoading = false;

  Timer? _statusUpdateTimer;
  final Map<String, String> _lastNotifiedStates = {};

  // Filters
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedTeam = '';
  String _selectedStage = ''; // 'Group Stage', 'Round of 32', etc.
  String _selectedGroup = ''; // 'Group A', 'Group B', etc.

  ScheduleProvider() {
    loadSchedule().then((_) {
      _initializeNotifiedStates();
      _startStatusUpdateTimer();
    });
  }

  // Getters
  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime? get selectedDate => _selectedDate;
  String get selectedTeam => _selectedTeam;
  String get selectedStage => _selectedStage;
  String get selectedGroup => _selectedGroup;

  List<MatchModel> get liveMatches =>
      _matches.where((m) => m.status == 'live').toList();

  List<MatchModel> getTodayMatches(DateTime referenceDate) {
    return _matches.where((m) {
      final matchLocal = m.dateTime.toLocal();
      final refLocal = referenceDate.toLocal();
      final sameLocal = matchLocal.year == refLocal.year &&
          matchLocal.month == refLocal.month &&
          matchLocal.day == refLocal.day;

      final matchUtc = m.dateTime.toUtc();
      final refUtc = referenceDate.toUtc();
      final sameUtc = matchUtc.year == refUtc.year &&
          matchUtc.month == refUtc.month &&
          matchUtc.day == refUtc.day;

      return sameLocal || sameUtc;
    }).toList();
  }

  // Next upcoming matches (for the dashboard when no live matches are active)
  List<MatchModel> getUpcomingMatches(int limit) {
    final upcoming = _matches.where((m) => m.status == 'upcoming').toList();
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.take(limit).toList();
  }

  // Filtered schedule list
  List<MatchModel> get filteredMatches {
    return _matches.where((match) {
      // Search text filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesHome = match.homeTeam.toLowerCase().contains(query);
        final matchesAway = match.awayTeam.toLowerCase().contains(query);
        final matchesVenue = match.venue.toLowerCase().contains(query);
        final matchesCity = match.city.toLowerCase().contains(query);
        if (!matchesHome && !matchesAway && !matchesVenue && !matchesCity) {
          return false;
        }
      }

      // Date filter
      if (_selectedDate != null) {
        final matchLocal = match.dateTime.toLocal();
        final filterLocal = _selectedDate!.toLocal();
        if (matchLocal.year != filterLocal.year ||
            matchLocal.month != filterLocal.month ||
            matchLocal.day != filterLocal.day) {
          return false;
        }
      }

      // Team filter
      if (_selectedTeam.isNotEmpty) {
        final team = _selectedTeam.toLowerCase();
        if (match.homeTeam.toLowerCase() != team &&
            match.awayTeam.toLowerCase() != team) {
          return false;
        }
      }

      // Stage filter
      if (_selectedStage.isNotEmpty) {
        if (match.stage != _selectedStage) {
          return false;
        }
      }

      // Group filter
      if (_selectedGroup.isNotEmpty) {
        if (match.groupName != _selectedGroup) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Unique list of stages for filter options
  List<String> get allStages {
    final stages = _matches.map((m) => m.stage).toSet().toList();
    stages.sort();
    return stages;
  }

  // Unique list of groups for filter options
  List<String> get allGroups {
    final groups = _matches
        .map((m) => m.groupName)
        .where((g) => g != 'N/A' && g.isNotEmpty)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  // Unique list of teams for filter options
  List<String> get allTeams {
    final teams = <String>{};
    for (var m in _matches) {
      if (!m.homeTeam.contains('Winner') && !m.homeTeam.contains('Runner-up')) {
        teams.add(m.homeTeam);
      }
      if (!m.awayTeam.contains('Winner') && !m.awayTeam.contains('Runner-up')) {
        teams.add(m.awayTeam);
      }
    }
    final list = teams.toList();
    list.sort();
    return list;
  }

  Future<void> loadSchedule() async {
    _isLoading = true;
    notifyListeners();

    _matches = await _repository.loadMatches();
    _matches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    _isLoading = false;
    notifyListeners();
  }

  // Filter setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTeam(String team) {
    _selectedTeam = team;
    notifyListeners();
  }

  void setSelectedStage(String stage) {
    _selectedStage = stage;
    notifyListeners();
  }

  void setSelectedGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDate = null;
    _selectedTeam = '';
    _selectedStage = '';
    _selectedGroup = '';
    notifyListeners();
  }

  // Match Simulator controls
  Future<void> startMatch(String matchId, NotificationProvider notifProv) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      _matches[idx].status = 'live';
      _matches[idx].homeScore = 0;
      _matches[idx].awayScore = 0;
      _matches[idx].timeline = [
        TimelineEvent(
          minute: 0,
          type: 'kickoff',
          player: 'Referee',
          team: 'System',
          detail: 'Match Started at ${_matches[idx].venue}',
        )
      ];
      _lastNotifiedStates[_matches[idx].id] = "live_0_0";
      await _repository.saveMatches(_matches);
      notifyListeners();

      // Send alert
      await notifProv.triggerInstantMatchAlert(
        _matches[idx],
        '🔴 Match Started!',
        '${_matches[idx].homeTeam} vs ${_matches[idx].awayTeam} is now underway at ${_matches[idx].venue}!',
      );
    }
  }

  Future<void> addSimulatedGoal(
    String matchId,
    bool isHome,
    String player,
    int minute,
    NotificationProvider notifProv,
  ) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1 && _matches[idx].status == 'live') {
      final match = _matches[idx];
      if (isHome) {
        match.homeScore += 1;
      } else {
        match.awayScore += 1;
      }

      final teamName = isHome ? match.homeTeam : match.awayTeam;
      match.timeline.insert(
        0, // Add to top of list
        TimelineEvent(
          minute: minute,
          type: 'goal',
          player: player,
          team: teamName,
          detail: 'Goal! Score is now ${match.homeScore} - ${match.awayScore}',
        ),
      );
      _lastNotifiedStates[match.id] = "live_${match.homeScore}_${match.awayScore}";

      await _repository.saveMatches(_matches);
      notifyListeners();

      // Send Goal Alert
      await notifProv.triggerInstantMatchAlert(
        match,
        '⚽ GOAL! ($minute\')',
        '$player scores for $teamName! ${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
      );
    }
  }

  Future<void> addSimulatedCard(
    String matchId,
    bool isHome,
    String player,
    String cardType, // 'yellow_card' or 'red_card'
    int minute,
    NotificationProvider notifProv,
  ) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1 && _matches[idx].status == 'live') {
      final match = _matches[idx];
      final teamName = isHome ? match.homeTeam : match.awayTeam;

      match.timeline.insert(
        0,
        TimelineEvent(
          minute: minute,
          type: cardType,
          player: player,
          team: teamName,
          detail: cardType == 'red_card' ? 'Red Card' : 'Yellow Card',
        ),
      );

      await _repository.saveMatches(_matches);
      notifyListeners();

      final emoji = cardType == 'red_card' ? '🟥' : '🟨';
      await notifProv.triggerInstantMatchAlert(
        match,
        '$emoji Card Event ($minute\')',
        '$player ($teamName) received a ${cardType == 'red_card' ? 'red' : 'yellow'} card.',
      );
    }
  }

  Future<void> endMatch(String matchId, NotificationProvider notifProv) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1 && _matches[idx].status == 'live') {
      final match = _matches[idx];
      match.status = 'completed';
      match.timeline.insert(
        0,
        TimelineEvent(
          minute: 90,
          type: 'fulltime',
          player: 'Referee',
          team: 'System',
          detail: 'Full-Time: Final score ${match.homeScore} - ${match.awayScore}',
        ),
      );
      _lastNotifiedStates[match.id] = "completed_${match.homeScore}_${match.awayScore}";

      await _repository.saveMatches(_matches);
      notifyListeners();

      await notifProv.triggerInstantMatchAlert(
        match,
        '🏁 Match Completed!',
        'Full-Time: ${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
      );
    }
  }

  Future<void> resetSchedule() async {
    await _repository.resetSchedule();
    await loadSchedule();
  }

  void _initializeNotifiedStates() {
    final now = DateTime.now().toUtc();
    for (var m in _matches) {
      if (m.status == 'live') {
        _lastNotifiedStates[m.id] = "live_${m.homeScore}_${m.awayScore}";
      } else if (m.status == 'completed') {
        _lastNotifiedStates[m.id] = "completed_${m.homeScore}_${m.awayScore}";
      }
    }
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAndUpdatesMatchesDynamicState();
    });
  }

  void _checkAndUpdatesMatchesDynamicState() {
    if (_matches.isEmpty) return;

    final now = DateTime.now().toUtc();
    final changed = MatchRepository.updateMatchesStatusAndScores(_matches);
    if (!changed) return;

    bool shouldSave = false;

    for (var m in _matches) {
      final difference = m.dateTime.toUtc().difference(now);

      // 1. Kickoff Reminder (Starts in <= 15 minutes and > 0 minutes)
      if (difference.inMinutes <= 15 && difference.inMinutes > 0) {
        final stateKey = "upcoming_reminder";
        if (_lastNotifiedStates[m.id] != stateKey) {
          _lastNotifiedStates[m.id] = stateKey;
          shouldSave = true;

          if (StorageService.areNotificationsEnabled()) {
            NotificationService.showInstantNotification(
              id: m.matchNumber,
              title: '⚽ Match Starting Soon: ${m.homeTeam} vs ${m.awayTeam}',
              body: 'Kickoff in ${difference.inMinutes} minutes at ${m.venue}, ${m.city}!',
            );
          }
        }
      }

      // 2. Match Started / Score Changed (status is 'live')
      if (m.status == 'live') {
        final elapsed = m.getDisplayElapsedMinutes(now);
        final stateKey = "live_${m.homeScore}_${m.awayScore}";
        final lastState = _lastNotifiedStates[m.id];

        if (lastState == null || !lastState.startsWith("live")) {
          // Just transitioned from upcoming to live
          _lastNotifiedStates[m.id] = stateKey;
          shouldSave = true;

          if (StorageService.areNotificationsEnabled()) {
            NotificationService.showInstantNotification(
              id: m.matchNumber + 2000,
              title: '🔴 Match Started!',
              body: '${m.homeTeam} vs ${m.awayTeam} is now live at ${m.venue}!',
            );
          }
        } else if (lastState != stateKey) {
          // Score changed while live
          _lastNotifiedStates[m.id] = stateKey;
          shouldSave = true;

          if (StorageService.areNotificationsEnabled()) {
            NotificationService.showInstantNotification(
              id: m.matchNumber + 3000,
              title: '⚽ GOAL!',
              body: 'Live Score: ${m.homeTeam} ${m.homeScore} - ${m.awayScore} ${m.awayTeam} (${elapsed}\')',
            );
          }
        }
      }

      // 3. Match Completed (Transitions to 'completed')
      if (m.status == 'completed') {
        final stateKey = "completed_${m.homeScore}_${m.awayScore}";
        final lastState = _lastNotifiedStates[m.id];

        if (lastState != null && lastState.startsWith("live") && lastState != stateKey) {
          _lastNotifiedStates[m.id] = stateKey;
          shouldSave = true;

          if (StorageService.areNotificationsEnabled()) {
            NotificationService.showInstantNotification(
              id: m.matchNumber + 4000,
              title: '🏁 Match Completed!',
              body: 'Full-Time: ${m.homeTeam} ${m.homeScore} - ${m.awayScore} ${m.awayTeam}',
            );
          }
        }
      }
    }

    if (shouldSave) {
      _repository.saveMatches(_matches);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }
}
