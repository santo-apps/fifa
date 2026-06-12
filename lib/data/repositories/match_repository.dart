import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../../core/services/storage_service.dart';
import 'initial_schedule.dart';

class MatchGoals {
  final int minute;
  final String player;
  final bool isHome;
  MatchGoals(this.minute, this.player, this.isHome);
}

class MatchRepository {
  // Dictionary of flag emojis for all 48 participating countries in FIFA 2026
  static const Map<String, String> teamFlags = {
    'mexico': '🇲🇽',
    'south africa': '🇿🇦',
    'south korea': '🇰🇷',
    'korea republic': '🇰🇷',
    'czechia': '🇨🇿',
    'czech republic': '🇨🇿',
    'canada': '🇨🇦',
    'bosnia & herzegovina': '🇧🇦',
    'bosnia and herzegovina': '🇧🇦',
    'qatar': '🇶🇦',
    'switzerland': '🇨🇭',
    'brazil': '🇧🇷',
    'morocco': '🇲🇦',
    'haiti': '🇭🇹',
    'scotland': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    'usa': '🇺🇸',
    'united states': '🇺🇸',
    'paraguay': '🇵🇾',
    'australia': '🇦🇺',
    'turkiye': '🇹🇷',
    'turkey': '🇹🇷',
    'germany': '🇩🇪',
    'curacao': '🇨🇼',
    'curaçao': '🇨🇼',
    'cote d\'ivoire': '🇨🇮',
    'ecuador': '🇪🇨',
    'netherlands': '🇳🇱',
    'japan': '🇯🇵',
    'sweden': '🇸🇪',
    'tunisia': '🇹🇳',
    'belgium': '🇧🇪',
    'egypt': '🇪🇬',
    'iran': '🇮🇷',
    'new zealand': '🇳🇿',
    'spain': '🇪🇸',
    'cabo verde': '🇨🇻',
    'saudi arabia': '🇸🇦',
    'uruguay': '🇺🇾',
    'france': '🇫🇷',
    'senegal': '🇸🇳',
    'iraq': '🇮🇶',
    'norway': '🇳🇴',
    'argentina': '🇦🇷',
    'algeria': '🇩🇿',
    'austria': '🇦🇹',
    'jordan': '🇯🇴',
    'portugal': '🇵🇹',
    'dr congo': '🇨🇩',
    'uzbekistan': '🇺🇿',
    'colombia': '🇨🇴',
    'england': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    'croatia': '🇭🇷',
    'ghana': '🇬🇭',
    'panama': '🇵🇦',
    'ivory coast': '🇨🇮',
    'congo dr': '🇨🇩',
    'cape verde': '🇨🇻',
    'saudia arabia': '🇸🇦',
  };

  static String getFlag(String teamName) {
    return teamFlags[teamName.trim().toLowerCase()] ?? '🏳️';
  }

  static bool isTesting = false;

  static List<int> getDeterministicScore(int matchNumber) {
    final home = (matchNumber * 3 + 1) % 4;
    final away = (matchNumber * 7 + 2) % 3;
    return [home, away];
  }

  static List<MatchGoals> getMatchGoals(int matchNumber, String homeTeam, String awayTeam) {
    if (matchNumber == 1) {
      return [
        MatchGoals(23, 'H. Lozano', true),
        MatchGoals(65, 'J. Hernández', true),
      ];
    }
    if (matchNumber == 2) {
      return [
        MatchGoals(59, 'L. Krejčí', false),
        MatchGoals(67, 'I.B. Hwang', true),
        MatchGoals(80, 'H.G. Oh', true),
      ];
    }
    
    final List<MatchGoals> goals = [];
    final homeCount = (matchNumber * 3 + 1) % 4;
    final awayCount = (matchNumber * 7 + 2) % 3;
    
    for (int g = 0; g < homeCount; g++) {
      goals.add(MatchGoals(10 + g * 20, 'Home Player ${g + 1}', true));
    }
    for (int g = 0; g < awayCount; g++) {
      goals.add(MatchGoals(15 + g * 25, 'Away Player ${g + 1}', false));
    }
    return goals;
  }

  static void resolveMatchDynamicState(MatchModel m, DateTime now) {
    if (isTesting) return;
    final diff = now.difference(m.dateTime.toUtc());
    if (diff.isNegative) {
      m.status = 'upcoming';
      m.homeScore = 0;
      m.awayScore = 0;
      m.timeline = [];
      return;
    }
    
    final elapsed = diff.inMinutes;
    final goals = getMatchGoals(m.matchNumber, m.homeTeam, m.awayTeam);
    
    if (elapsed <= 120) {
      m.status = 'live';
      m.homeScore = goals.where((g) => g.isHome && g.minute <= elapsed).length;
      m.awayScore = goals.where((g) => !g.isHome && g.minute <= elapsed).length;
      
      final List<TimelineEvent> timeline = [
        TimelineEvent(
          minute: 0,
          type: 'kickoff',
          player: 'Referee',
          team: 'System',
          detail: 'Match Started at ${m.venue}',
        )
      ];
      if (elapsed > 45) {
        timeline.insert(
          0,
          TimelineEvent(
            minute: 45,
            type: 'info',
            player: 'Referee',
            team: 'System',
            detail: 'Half-Time',
          ),
        );
      }
      for (var g in goals) {
        if (g.minute <= elapsed) {
          timeline.insert(
            0,
            TimelineEvent(
              minute: g.minute,
              type: 'goal',
              player: g.player,
              team: g.isHome ? m.homeTeam : m.awayTeam,
              detail: 'Goal!',
            ),
          );
        }
      }
      m.timeline = timeline;
    } else {
      m.status = 'completed';
      m.homeScore = goals.where((g) => g.isHome).length;
      m.awayScore = goals.where((g) => !g.isHome).length;
      
      final List<TimelineEvent> timeline = [
        TimelineEvent(
          minute: 0,
          type: 'kickoff',
          player: 'Referee',
          team: 'System',
          detail: 'Match Started',
        )
      ];
      for (var g in goals) {
        timeline.insert(
          0,
          TimelineEvent(
            minute: g.minute,
            type: 'goal',
            player: g.player,
            team: g.isHome ? m.homeTeam : m.awayTeam,
            detail: 'Goal!',
          ),
        );
      }
      timeline.insert(
        0,
        TimelineEvent(
          minute: 90,
          type: 'fulltime',
          player: 'Referee',
          team: 'System',
          detail: 'Full-Time: Final score ${m.homeScore} - ${m.awayScore}',
        ),
      );
      m.timeline = timeline;
    }
  }

  static bool updateMatchesStatusAndScores(List<MatchModel> matches) {
    if (isTesting) return false;
    final now = DateTime.now().toUtc();
    for (var m in matches) {
      resolveMatchDynamicState(m, now);
    }
    return true;
  }

  // Parses date "2026-06-11" and time "13:00 UTC-6" into a correct UTC DateTime
  static DateTime parseDateTime(String dateStr, String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final hm = parts[0].split(':');
      final hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);

      final ymd = dateStr.trim().split('-');
      final year = int.parse(ymd[0]);
      final month = int.parse(ymd[1]);
      final day = int.parse(ymd[2]);

      var dt = DateTime.utc(year, month, day, hour, minute);

      if (parts.length > 1) {
        final tzStr = parts[1];
        if (tzStr.contains('UTC-')) {
          final offsetStr = tzStr.replaceAll('UTC-', '');
          final offset = int.tryParse(offsetStr) ?? 0;
          dt = dt.add(Duration(hours: offset));
        } else if (tzStr.contains('UTC+')) {
          final offsetStr = tzStr.replaceAll('UTC+', '');
          final offset = int.tryParse(offsetStr) ?? 0;
          dt = dt.subtract(Duration(hours: offset));
        }
      }
      return dt;
    } catch (e) {
      print("Error parsing DateTime: $e");
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  Future<List<MatchModel>> loadMatches() async {
    List<MatchModel>? networkMatches;

    // 1. Try fetching from the official openfootball network endpoint
    try {
      final response = await http
          .get(Uri.parse('https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        networkMatches = parseMatchesJson(response.body);
      }
    } catch (e) {
      print("Failed to sync matches from network API: $e. Falling back to local offline schedule.");
    }

    // 2. Load/Merge with cached matches from local storage
    try {
      final cachedJson = StorageService.getSimulatedMatchesJson();
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        final cachedMatches = decoded.map((item) => MatchModel.fromJson(item as Map<String, dynamic>)).toList();
        
        // Self-healing migration: if cached matches count is outdated, overwrite with complete initial schedule
        final initialCount = InitialSchedule.getMatches().length;
        if (cachedMatches.length < initialCount) {
          final initial = InitialSchedule.getMatches();
          if (networkMatches != null && networkMatches.isNotEmpty) {
            for (var m in initial) {
              final nm = networkMatches.firstWhere((n) => n.matchNumber == m.matchNumber, orElse: () => m);
              m.status = nm.status;
              m.homeScore = nm.homeScore;
              m.awayScore = nm.awayScore;
              m.timeline = nm.timeline;
            }
          } else {
            updateMatchesStatusAndScores(initial);
          }
          await saveMatches(initial);
          return initial;
        }

        // Merge network scores if available
        if (networkMatches != null && networkMatches.isNotEmpty) {
          for (var cm in cachedMatches) {
            final nm = networkMatches.firstWhere((n) => n.matchNumber == cm.matchNumber, orElse: () => cm);
            cm.status = nm.status;
            cm.homeScore = nm.homeScore;
            cm.awayScore = nm.awayScore;
            cm.timeline = nm.timeline;
          }
          await saveMatches(cachedMatches);
        } else {
          final changed = updateMatchesStatusAndScores(cachedMatches);
          if (changed) {
            await saveMatches(cachedMatches);
          }
        }
        return cachedMatches;
      }
    } catch (e) {
      print("Error loading cached matches: $e");
    }

    // 3. Fallback/New Start
    if (networkMatches != null && networkMatches.isNotEmpty) {
      await saveMatches(networkMatches);
      return networkMatches;
    }

    final initial = InitialSchedule.getMatches();
    updateMatchesStatusAndScores(initial);
    await saveMatches(initial);
    return initial;
  }

  static List<MatchModel> parseMatchesJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List<dynamic> matchesList = data['matches'] ?? [];
      final List<MatchModel> parsedMatches = [];
      
      for (var i = 0; i < matchesList.length; i++) {
        final m = matchesList[i];
        
        // Robust Team Parsing (strings or nested maps)
        final team1Val = m['team1'];
        final team2Val = m['team2'];
        String homeTeam = 'Home Team';
        String awayTeam = 'Away Team';
        if (team1Val is String) {
          homeTeam = team1Val;
        } else if (team1Val is Map) {
          homeTeam = team1Val['name'] as String? ?? 'Home Team';
        }
        if (team2Val is String) {
          awayTeam = team2Val;
        } else if (team2Val is Map) {
          awayTeam = team2Val['name'] as String? ?? 'Away Team';
        }

        final dateStr = m['date'] as String? ?? '2026-06-11';
        final timeStr = m['time'] as String? ?? '12:00 UTC';
        final matchTime = parseDateTime(dateStr, timeStr);
        
        // Defensive Score Parsing (strings, integers, nulls)
        int? homeScore;
        int? awayScore;
        if (m['score1'] != null) {
          homeScore = int.tryParse(m['score1'].toString());
        }
        if (m['score2'] != null) {
          awayScore = int.tryParse(m['score2'].toString());
        }
        final hasResult = homeScore != null && awayScore != null;

        final now = DateTime.now().toUtc();
        String status = 'upcoming';
        if (hasResult) {
          status = 'completed';
        } else if (!isTesting) {
          final diff = now.difference(matchTime);
          if (!diff.isNegative) {
            if (diff.inMinutes <= 120) {
              status = 'live';
            } else {
              status = 'completed';
            }
          }
        }

        List<TimelineEvent> timeline = [];
        if (hasResult) {
          timeline.add(
            TimelineEvent(
              minute: 0,
              type: 'kickoff',
              player: 'Referee',
              team: 'System',
              detail: 'Match Started',
            ),
          );
          final hScore = homeScore ?? 0;
          for (int g = 0; g < hScore; g++) {
            timeline.insert(
              0,
              TimelineEvent(
                minute: 10 + g * 20,
                type: 'goal',
                player: 'Home Player ${g + 1}',
                team: homeTeam,
                detail: 'Goal!',
              ),
            );
          }
          final aScore = awayScore ?? 0;
          for (int g = 0; g < aScore; g++) {
            timeline.insert(
              0,
              TimelineEvent(
                minute: 15 + g * 25,
                type: 'goal',
                player: 'Away Player ${g + 1}',
                team: awayTeam,
                detail: 'Goal!',
              ),
            );
          }
          timeline.insert(
            0,
            TimelineEvent(
              minute: 90,
              type: 'fulltime',
              player: 'Referee',
              team: 'System',
              detail: 'Full-Time: Final score $homeScore - $awayScore',
            ),
          );
        } else if (!isTesting) {
          final mockModel = MatchModel(
            id: 'temp',
            matchNumber: i + 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeFlag: '',
            awayFlag: '',
            dateTime: matchTime,
            venue: m['ground'] as String? ?? 'Stadium Venue',
            city: m['ground'] as String? ?? 'Host City',
            country: 'Host Nation',
            stage: m['round'] as String? ?? 'Group Stage',
            groupName: m['group'] as String? ?? 'N/A',
          );
          resolveMatchDynamicState(mockModel, now);
          status = mockModel.status;
          homeScore = mockModel.homeScore;
          awayScore = mockModel.awayScore;
          timeline = mockModel.timeline;
        } else {
          homeScore = 0;
          awayScore = 0;
          timeline = [];
        }

        parsedMatches.add(
          MatchModel(
            id: 'match_${i + 1}',
            matchNumber: i + 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeFlag: getFlag(homeTeam),
            awayFlag: getFlag(awayTeam),
            dateTime: matchTime,
            venue: m['ground'] as String? ?? 'Stadium Venue',
            city: m['ground'] as String? ?? 'Host City',
            country: 'Host Nation',
            stage: m['round'] as String? ?? 'Group Stage',
            groupName: m['group'] as String? ?? 'N/A',
            status: status,
            homeScore: homeScore ?? 0,
            awayScore: awayScore ?? 0,
            timeline: timeline,
          ),
        );
      }
      return parsedMatches;
    } catch (e) {
      print("Error parsing matches JSON: $e");
      return [];
    }
  }

  Future<void> saveMatches(List<MatchModel> matches) async {
    try {
      final jsonStr = json.encode(matches.map((m) => m.toJson()).toList());
      await StorageService.saveSimulatedMatchesJson(jsonStr);
    } catch (e) {
      print("Error saving matches: $e");
    }
  }

  Future<void> resetSchedule() async {
    await StorageService.clearSimulatedMatches();
  }
}
