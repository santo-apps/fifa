class TimelineEvent {
  final int minute;
  final String type; // 'goal', 'yellow_card', 'red_card', 'sub'
  final String player;
  final String team;
  final String? detail; // e.g. "Assist by PlayerName"

  TimelineEvent({
    required this.minute,
    required this.type,
    required this.player,
    required this.team,
    this.detail,
  });

  Map<String, dynamic> toJson() {
    return {
      'minute': minute,
      'type': type,
      'player': player,
      'team': team,
      'detail': detail,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      minute: json['minute'] as int,
      type: json['type'] as String,
      player: json['player'] as String,
      team: json['team'] as String,
      detail: json['detail'] as String?,
    );
  }
}

class MatchModel {
  final String id;
  final int matchNumber;
  final String homeTeam;
  final String awayTeam;
  final String homeFlag; // Emoji flag or code
  final String awayFlag;
  final DateTime dateTime; // Scheduled kickoff in UTC
  final String venue;
  final String city;
  final String country; // USA, Mexico, Canada
  final String stage; // 'Group Stage', 'Round of 32', etc.
  final String groupName; // 'Group A', 'Group B', or 'N/A'

  // Dynamic fields that change during simulator / live update
  String status; // 'upcoming', 'live', 'completed'
  int homeScore;
  int awayScore;
  List<TimelineEvent> timeline;

  MatchModel({
    required this.id,
    required this.matchNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeFlag,
    required this.awayFlag,
    required this.dateTime,
    required this.venue,
    required this.city,
    required this.country,
    required this.stage,
    required this.groupName,
    this.status = 'upcoming',
    this.homeScore = 0,
    this.awayScore = 0,
    List<TimelineEvent>? timeline,
  }) : timeline = timeline ?? [];

  int getDisplayElapsedMinutes(DateTime now) {
    final rawElapsed = now.toUtc().difference(dateTime.toUtc()).inMinutes;
    if (rawElapsed < 0) return 0;
    if (rawElapsed <= 45) return rawElapsed;
    if (rawElapsed <= 60) return 45;
    return rawElapsed - 15;
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchNumber': matchNumber,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeFlag': homeFlag,
      'awayFlag': awayFlag,
      'dateTime': dateTime.toIso8601String(),
      'venue': venue,
      'city': city,
      'country': country,
      'stage': stage,
      'groupName': groupName,
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'timeline': timeline.map((e) => e.toJson()).toList(),
    };
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      matchNumber: json['matchNumber'] as int,
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      homeFlag: json['homeFlag'] as String,
      awayFlag: json['awayFlag'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      venue: json['venue'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      stage: json['stage'] as String,
      groupName: json['groupName'] as String,
      status: json['status'] as String? ?? 'upcoming',
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  MatchModel copyWith({
    String? status,
    int? homeScore,
    int? awayScore,
    List<TimelineEvent>? timeline,
  }) {
    return MatchModel(
      id: id,
      matchNumber: matchNumber,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeFlag: homeFlag,
      awayFlag: awayFlag,
      dateTime: dateTime,
      venue: venue,
      city: city,
      country: country,
      stage: stage,
      groupName: groupName,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      timeline: timeline ?? this.timeline,
    );
  }
}
