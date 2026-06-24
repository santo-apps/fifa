import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/match_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/theme.dart';
import '../screens/match_detail_screen.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEE, MMM d').format(match.dateTime.toLocal());
    final timeStr = DateFormat('jm').format(match.dateTime.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailScreen(matchId: match.id),
            ),
          );
        },
        child: Container(
          decoration: AppTheme.glassBoxDecoration(context: context),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match details header: Group/Stage & Country Flag/Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.status == 'live'
                          ? Colors.red.withOpacity(0.15)
                          : isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (match.status == 'live') ...[
                          const _LivePulseIndicator(),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ] else ...[
                          Text(
                            match.status == 'completed'
                                ? (match.homeScore > match.awayScore
                                    ? 'WON BY ${match.homeTeam.toUpperCase()}'
                                    : match.awayScore > match.homeScore
                                        ? 'WON BY ${match.awayTeam.toUpperCase()}'
                                        : 'DRAWN')
                                : 'UPCOMING',
                            style: TextStyle(
                              color: match.status == 'completed'
                                  ? (isDark ? Colors.white60 : Colors.black54)
                                  : Theme.of(context).colorScheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${match.stage} • ${match.groupName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action Buttons (Bookmark & Reminder)
                      _BookmarkButton(matchId: match.id),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Match content (Teams, flags, scores / schedule times)
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.homeFlag,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Middle Score or Kickoff Time
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (match.status == 'live' || match.status == 'completed') ...[
                          Text(
                            '${match.homeScore} - ${match.awayScore}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (match.status == 'live') ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final displayMin = match.getDisplayElapsedMinutes(DateTime.now());
                                return Text(
                                  '$displayMin\'',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.awayFlag,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Venue and location info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${match.venue}, ${match.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (match.status == 'upcoming') ...[
                    Consumer<NotificationProvider>(
                      builder: (context, notifProv, _) {
                        final hasRem = notifProv.hasReminder(match.id);
                        return GestureDetector(
                          onTap: () => notifProv.toggleReminder(match),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasRem
                                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasRem
                                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasRem ? Icons.notifications_active : Icons.notifications_none_rounded,
                                  size: 12,
                                  color: hasRem ? Theme.of(context).colorScheme.secondary : (isDark ? Colors.white60 : Colors.black54),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasRem ? 'Alert Set' : 'Remind Me',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: hasRem ? Theme.of(context).colorScheme.secondary : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final String matchId;

  const _BookmarkButton({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favProv, _) {
        final isBookmarked = favProv.isMatchBookmarked(matchId);
        return InkWell(
          onTap: () => favProv.toggleBookmarkMatch(matchId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isBookmarked ? Theme.of(context).colorScheme.secondary : Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _LivePulseIndicator extends StatefulWidget {
  const _LivePulseIndicator();

  @override
  State<_LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<_LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
