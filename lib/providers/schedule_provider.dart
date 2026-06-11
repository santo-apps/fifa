import 'package:flutter/material.dart';
import '../data/models/match_model.dart';
import '../data/repositories/match_repository.dart';
import 'notification_provider.dart';

class ScheduleProvider extends ChangeNotifier {
  final MatchRepository _repository = MatchRepository();

  List<MatchModel> _matches = [];
  bool _isLoading = false;

  // Filters
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedTeam = '';
  String _selectedStage = ''; // 'Group Stage', 'Round of 32', etc.
  String _selectedGroup = ''; // 'Group A', 'Group B', etc.

  ScheduleProvider() {
    loadSchedule();
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

  // Today's matches relative to a date. We'll default to the current system date.
  // Since the user is testing on June 10/11, 2026, let's extract matches on the same day in local/UTC.
  List<MatchModel> getTodayMatches(DateTime referenceDate) {
    return _matches.where((m) {
      final matchLocal = m.dateTime.toLocal();
      return matchLocal.year == referenceDate.year &&
          matchLocal.month == referenceDate.month &&
          matchLocal.day == referenceDate.day;
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
}
