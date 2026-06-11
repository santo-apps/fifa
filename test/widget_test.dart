import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fifa/data/models/match_model.dart';
import 'package:fifa/core/services/storage_service.dart';
import 'package:fifa/providers/favorites_provider.dart';
import 'package:fifa/providers/schedule_provider.dart';
import 'package:fifa/providers/standings_provider.dart';
import 'package:fifa/data/repositories/match_repository.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'favorite_teams': ['mexico'],
      'bookmarked_matches': ['match_1'],
    });
    await StorageService.init();
  });

  group('Match Model Tests', () {
    test('JSON serialization & deserialization', () {
      final match = MatchModel(
        id: 'test_match',
        matchNumber: 99,
        homeTeam: 'Home Team',
        awayTeam: 'Away Team',
        homeFlag: '🏳️',
        awayFlag: '🏳️',
        dateTime: DateTime.utc(2026, 6, 11, 20, 0),
        venue: 'Stadium Name',
        city: 'City Name',
        country: 'Country Name',
        stage: 'Group Stage',
        groupName: 'Group A',
      );

      final jsonMap = match.toJson();
      expect(jsonMap['id'], 'test_match');
      expect(jsonMap['matchNumber'], 99);

      final decoded = MatchModel.fromJson(jsonMap);
      expect(decoded.id, 'test_match');
      expect(decoded.matchNumber, 99);
    });
  });

  group('Favorites Provider Tests', () {
    test('Check default loaded favorites and toggles', () async {
      final favProv = FavoritesProvider();

      expect(favProv.isTeamFavorite('Mexico'), true);
      expect(favProv.isTeamFavorite('USA'), false);
      expect(favProv.isMatchBookmarked('match_1'), true);
      expect(favProv.isMatchBookmarked('match_2'), false);

      await favProv.toggleFavoriteTeam('USA');
      expect(favProv.isTeamFavorite('USA'), true);
    });
  });

  group('Schedule Provider Tests', () {
    test('Filters schedule matches correctly by search query', () async {
      final scheduleProv = ScheduleProvider();
      await scheduleProv.loadSchedule();

      scheduleProv.setSearchQuery('Mexico');
      expect(scheduleProv.filteredMatches.any((m) => m.homeTeam == 'Mexico' || m.awayTeam == 'Mexico'), true);
    });
  });

  group('Standings Calculations Tests', () {
    test('Standings are calculated dynamically for Group A', () async {
      final scheduleProv = ScheduleProvider();
      await scheduleProv.loadSchedule();

      final standingsProv = StandingsProvider(scheduleProvider: scheduleProv);
      
      // Initially no matches are completed, all points are 0
      final standings = standingsProv.groupStandings['Group A']!;
      expect(standings.length, 4);
      expect(standings.every((t) => t.points == 0), true);

      // Complete a match in Group A: Mexico beats South Africa 2 - 1
      final matches = scheduleProv.matches;
      final mIdx = matches.indexWhere((m) => m.id == 'match_1');
      expect(mIdx != -1, true);

      matches[mIdx].status = 'completed';
      matches[mIdx].homeScore = 2;
      matches[mIdx].awayScore = 1;

      // Force calculate standings by triggering a ScheduleProvider notification
      scheduleProv.setSearchQuery('trigger_recalculate');

      final updatedStandings = standingsProv.groupStandings['Group A']!;
      final mexico = updatedStandings.firstWhere((t) => t.teamName == 'Mexico');
      final southAfrica = updatedStandings.firstWhere((t) => t.teamName == 'South Africa');

      expect(mexico.points, 3);
      expect(mexico.played, 1);
      expect(mexico.goalDifference, 1);

      expect(southAfrica.points, 0);
      expect(southAfrica.played, 1);
      expect(southAfrica.goalDifference, -1);
    });
  });

  group('MatchRepository Parsing Tests', () {
    test('Robust parsing of varying JSON structures', () {
      final mockJsonStr = '''
      {
        "name": "World Cup 2026",
        "matches": [
          {
            "round": "Group Stage",
            "date": "2026-06-11",
            "time": "19:00 UTC",
            "team1": "Mexico",
            "team2": {
              "name": "South Africa",
              "code": "RSA"
            },
            "score1": "2",
            "score2": 1,
            "group": "Group A",
            "ground": "Estadio Azteca"
          },
          {
            "round": "Group Stage",
            "date": "2026-06-12",
            "time": "22:00 UTC",
            "team1": {
              "name": "Canada",
              "code": "CAN"
            },
            "team2": "Bosnia and Herzegovina",
            "score1": null,
            "score2": null,
            "group": "Group B",
            "ground": "BMO Field"
          }
        ]
      }
      ''';

      final parsed = MatchRepository.parseMatchesJson(mockJsonStr);
      
      expect(parsed.length, 2);
      
      // Match 1
      expect(parsed[0].homeTeam, 'Mexico');
      expect(parsed[0].awayTeam, 'South Africa');
      expect(parsed[0].homeScore, 2);
      expect(parsed[0].awayScore, 1);
      expect(parsed[0].status, 'completed');
      expect(parsed[0].homeFlag, '🇲🇽');
      expect(parsed[0].awayFlag, '🇿🇦');
      
      // Match 2
      expect(parsed[1].homeTeam, 'Canada');
      expect(parsed[1].awayTeam, 'Bosnia and Herzegovina');
      expect(parsed[1].homeScore, 0);
      expect(parsed[1].awayScore, 0);
      expect(parsed[1].status, 'upcoming');
      expect(parsed[1].homeFlag, '🇨🇦');
      expect(parsed[1].awayFlag, '🇧🇦');
    });

    test('Dynamic live status resolution based on scheduled kickoff', () {
      final kickoff = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
      final dateStr = "${kickoff.year}-${kickoff.month.toString().padLeft(2, '0')}-${kickoff.day.toString().padLeft(2, '0')}";
      final timeStr = "${kickoff.hour.toString().padLeft(2, '0')}:${kickoff.minute.toString().padLeft(2, '0')} UTC";

      final mockJsonStr = '''
      {
        "name": "World Cup 2026",
        "matches": [
          {
            "round": "Group Stage",
            "date": "$dateStr",
            "time": "$timeStr",
            "team1": "Mexico",
            "team2": "South Africa",
            "score1": null,
            "score2": null,
            "group": "Group A",
            "ground": "Estadio Azteca"
          }
        ]
      }
      ''';

      final parsed = MatchRepository.parseMatchesJson(mockJsonStr);
      expect(parsed.length, 1);
      expect(parsed[0].status, 'live');
      expect(parsed[0].timeline.isNotEmpty, true);
      expect(parsed[0].timeline.last.type, 'kickoff');
    });
  });
}
