import 'package:flutter/material.dart';
import 'schedule_provider.dart';

class TeamStanding {
  final String teamName;
  final String flag;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  TeamStanding({required this.teamName, required this.flag});

  int get goalDifference => goalsFor - goalsAgainst;
  int get points => won * 3 + drawn;
}

class StandingsProvider extends ChangeNotifier {
  final ScheduleProvider scheduleProvider;
  Map<String, List<TeamStanding>> _groupStandings = {};

  StandingsProvider({required this.scheduleProvider}) {
    scheduleProvider.addListener(_calculateStandings);
    _calculateStandings();
  }

  @override
  void dispose() {
    scheduleProvider.removeListener(_calculateStandings);
    super.dispose();
  }

  Map<String, List<TeamStanding>> get groupStandings => _groupStandings;

  // Sorted list of unique group names (Group A, Group B, etc.)
  List<String> get groupNames {
    final names = _groupStandings.keys.toList();
    names.sort();
    return names;
  }

  void _calculateStandings() {
    final matches = scheduleProvider.matches;
    final Map<String, Map<String, TeamStanding>> tempStandings = {};

    // 1. Initialize all teams in their respective groups
    for (var m in matches) {
      if (m.groupName == 'N/A' ||
          m.groupName.isEmpty ||
          !m.groupName.startsWith('Group')) {
        continue;
      }

      final group = m.groupName;
      tempStandings.putIfAbsent(group, () => {});

      tempStandings[group]!.putIfAbsent(
        m.homeTeam,
        () => TeamStanding(teamName: m.homeTeam, flag: m.homeFlag),
      );
      tempStandings[group]!.putIfAbsent(
        m.awayTeam,
        () => TeamStanding(teamName: m.awayTeam, flag: m.awayFlag),
      );
    }

    // 2. Count statistics for completed matches
    for (var m in matches) {
      if (m.groupName == 'N/A' ||
          m.groupName.isEmpty ||
          !m.groupName.startsWith('Group')) {
        continue;
      }
      if (m.status != 'completed') continue;

      final group = m.groupName;
      final home = tempStandings[group]?[m.homeTeam];
      final away = tempStandings[group]?[m.awayTeam];

      if (home != null && away != null) {
        home.played += 1;
        away.played += 1;
        home.goalsFor += m.homeScore;
        home.goalsAgainst += m.awayScore;
        away.goalsFor += m.awayScore;
        away.goalsAgainst += m.homeScore;

        if (m.homeScore > m.awayScore) {
          home.won += 1;
          away.lost += 1;
        } else if (m.homeScore < m.awayScore) {
          away.won += 1;
          home.lost += 1;
        } else {
          home.drawn += 1;
          away.drawn += 1;
        }
      }
    }

    // 3. Sort team lists in each group according to WC rules
    final Map<String, List<TeamStanding>> sortedStandings = {};
    tempStandings.forEach((group, teamMap) {
      final list = teamMap.values.toList();
      list.sort((a, b) {
        // a. Compare points
        if (b.points != a.points) {
          return b.points.compareTo(a.points);
        }
        // b. Compare goal difference
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        // c. Compare goals scored
        if (b.goalsFor != a.goalsFor) {
          return b.goalsFor.compareTo(a.goalsFor);
        }
        // d. Fallback to alphabetical order
        return a.teamName.compareTo(b.teamName);
      });
      sortedStandings[group] = list;
    });

    _groupStandings = sortedStandings;
    notifyListeners();
  }
}
