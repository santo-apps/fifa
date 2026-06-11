import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/match_model.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/theme.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _useUtcTimezone = false;

  void _shareMatch(MatchModel match) {
    final format = DateFormat('EEE, MMM d @ h:mm a');
    final timeStr = format.format(match.dateTime.toLocal());
    final shareText =
        '⚽ FIFA 2026 World Cup Match!\n'
        '${match.homeFlag} ${match.homeTeam} vs ${match.awayTeam} ${match.awayFlag}\n'
        '📅 Time: $timeStr (Local Time)\n'
        '🏟️ Venue: ${match.venue}, ${match.city}\n'
        'Follow live scores and schedules in the FIFA 2026 Schedule App!';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Match Details')),
      body: Consumer3<ScheduleProvider, FavoritesProvider, NotificationProvider>(
        builder: (context, scheduleProv, favProv, notifProv, _) {
          final matchIndex = scheduleProv.matches.indexWhere(
            (m) => m.id == widget.matchId,
          );
          if (matchIndex == -1) {
            return const Center(child: Text('Match not found'));
          }

          final match = scheduleProv.matches[matchIndex];
          final isBookmarked = favProv.isMatchBookmarked(match.id);
          final hasReminder = notifProv.hasReminder(match.id);

          final localTimeStr = DateFormat(
            'EEEE, MMMM d, y • h:mm a',
          ).format(match.dateTime.toLocal());
          final utcTimeStr =
              '${DateFormat('EEEE, MMMM d, y • h:mm a').format(match.dateTime.toUtc())} UTC';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium Glassmorphic Scoreboard card
              Container(
                decoration: AppTheme.glassBoxDecoration(context: context),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    // Stage Header & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${match.stage} • ${match.groupName}'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isBookmarked
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey,
                              ),
                              onPressed: () =>
                                  favProv.toggleBookmarkMatch(match.id),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.share_rounded,
                                color: Colors.grey,
                              ),
                              onPressed: () => _shareMatch(match),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Flag Score Flags
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Home
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.homeFlag,
                                style: const TextStyle(fontSize: 54),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                match.homeTeam,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score / Live status
                        Expanded(
                          child: Column(
                            children: [
                              if (match.status == 'live' ||
                                  match.status == 'completed') ...[
                                Text(
                                  '${match.homeScore} - ${match.awayScore}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: match.status == 'live'
                                        ? Colors.red.withOpacity(0.15)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      String badgeText = 'COMPLETED';
                                      if (match.status == 'live') {
                                        final elapsed = DateTime.now()
                                            .toUtc()
                                            .difference(match.dateTime.toUtc())
                                            .inMinutes;
                                        final displayMin = elapsed < 0
                                            ? 0
                                            : (elapsed > 120 ? 120 : elapsed);
                                        badgeText = 'LIVE - $displayMin\'';
                                      }
                                      return Text(
                                        badgeText,
                                        style: TextStyle(
                                          color: match.status == 'live'
                                              ? Colors.redAccent
                                              : Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 28,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'UPCOMING',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Away
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.awayFlag,
                                style: const TextStyle(fontSize: 54),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                match.awayTeam,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Timezone and reminder block
              Container(
                decoration: AppTheme.glassBoxDecoration(context: context),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kickoff Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        // Timezone Toggle switch
                        Row(
                          children: [
                            Text(
                              _useUtcTimezone ? 'UTC' : 'My Local Time',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Switch(
                              value: _useUtcTimezone,
                              activeThumbColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              onChanged: (val) {
                                setState(() {
                                  _useUtcTimezone = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      _useUtcTimezone ? utcTimeStr : localTimeStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (match.status == 'upcoming') ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => notifProv.toggleReminder(match),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasReminder
                              ? Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1)
                              : AppTheme.primaryGreen,
                          foregroundColor: hasReminder
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                          elevation: 0,
                          side: hasReminder
                              ? BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  width: 1,
                                )
                              : null,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          hasReminder
                              ? Icons.notifications_active
                              : Icons.notifications_none_rounded,
                        ),
                        label: Text(
                          hasReminder
                              ? 'Reminder Scheduled (15m before)'
                              : 'Get Match Reminders',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Venue Info block
              Container(
                decoration: AppTheme.glassBoxDecoration(context: context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.stadium_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.venue,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${match.city}, ${match.country}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Event Timeline header
              Text(
                match.status == 'upcoming' ? 'PRE-MATCH INFO' : 'MATCH EVENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Event Timeline content
              if (match.status == 'upcoming')
                Container(
                  decoration: AppTheme.glassBoxDecoration(context: context),
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 36,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Match not started yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live scores, cards, goals, and event timelines will appear here once the match kicks off.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (match.timeline.isEmpty)
                const Center(child: Text('No timeline events recorded.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: match.timeline.length,
                  itemBuilder: (context, idx) {
                    final ev = match.timeline[idx];
                    return _buildTimelineEventRow(context, ev);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineEventRow(BuildContext context, TimelineEvent ev) {
    IconData icon;
    Color iconColor;

    switch (ev.type) {
      case 'kickoff':
        icon = Icons.sports_rounded;
        iconColor = Colors.greenAccent;
        break;
      case 'goal':
        icon = Icons.sports_soccer_rounded;
        iconColor = Colors.white;
        break;
      case 'yellow_card':
        icon = Icons.crop_portrait_rounded;
        iconColor = Colors.yellowAccent;
        break;
      case 'red_card':
        icon = Icons.crop_portrait_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'fulltime':
        icon = Icons.sports_outlined;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AppTheme.glassBoxDecoration(context: context),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Event Time Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${ev.minute}\'',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Icon indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.15),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 16),

            // Player / Event Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev.player,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (ev.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      ev.detail!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              ev.team,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
