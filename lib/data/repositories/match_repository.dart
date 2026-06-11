import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../../core/services/storage_service.dart';
import 'initial_schedule.dart';

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
    // 1. Try loading cached simulator/modified schedule from local storage
    try {
      final cachedJson = StorageService.getSimulatedMatchesJson();
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        final cachedMatches = decoded.map((item) => MatchModel.fromJson(item as Map<String, dynamic>)).toList();
        
        // Self-healing migration: if cached matches count is outdated, overwrite with complete initial schedule
        final initialCount = InitialSchedule.getMatches().length;
        if (cachedMatches.length < initialCount) {
          final initial = InitialSchedule.getMatches();
          await saveMatches(initial);
          return initial;
        }
        return cachedMatches;
      }
    } catch (e) {
      print("Error loading cached matches: $e");
    }

    // 2. Try fetching from the official openfootball network endpoint
    try {
      final response = await http
          .get(Uri.parse('https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final parsedMatches = parseMatchesJson(response.body);
        if (parsedMatches.isNotEmpty) {
          await saveMatches(parsedMatches);
          return parsedMatches;
        }
      }
    } catch (e) {
      print("Failed to sync matches from network API: $e. Falling back to local offline schedule.");
    }

    // 3. Fallback to pre-populated official schedule offline
    final initial = InitialSchedule.getMatches();
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

        // Dynamic Live Status Resolution (kickoff to kickoff + 120 mins)
        String status = 'upcoming';
        if (hasResult) {
          status = 'completed';
        } else {
          final now = DateTime.now().toUtc();
          final diff = now.difference(matchTime);
          if (!diff.isNegative && diff.inMinutes <= 120) {
            status = 'live';
          }
        }

        // Generate timeline for dynamic live status
        final List<TimelineEvent> timeline = [];
        if (status == 'live') {
          final elapsed = DateTime.now().toUtc().difference(matchTime).inMinutes;
          timeline.add(
            TimelineEvent(
              minute: 0,
              type: 'kickoff',
              player: 'Referee',
              team: 'System',
              detail: 'Match Started at ${m['ground'] as String? ?? 'Stadium Venue'}',
            ),
          );
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
