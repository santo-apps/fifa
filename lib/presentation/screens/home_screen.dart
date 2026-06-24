import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/countdown_timer.dart';
import '../../core/constants/theme.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    // Opening match is June 11, 2026, at 22:00 UTC
    final openingMatchDate = DateTime.utc(2026, 6, 11, 22, 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.secondary, size: 24),
            const SizedBox(width: 8),
            Text(
              'WC 2026',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProv, _) {
          if (scheduleProv.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
            );
          }

          final live = scheduleProv.liveMatches;
          final today = scheduleProv.getTodayMatches(currentDate);
          final upcoming = scheduleProv.getUpcomingMatches(3);

          return RefreshIndicator(
            color: Theme.of(context).colorScheme.secondary,
            onRefresh: () => scheduleProv.loadSchedule(),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Live matches section (or countdown)
                if (live.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE NOW',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: live.length,
                      itemBuilder: (context, idx) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width - 48,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: MatchCard(match: live[idx]),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // If opening match is in the future, show countdown
                  if (openingMatchDate.isAfter(DateTime.now()))
                    CountdownTimer(targetDate: openingMatchDate),
                ],

                const SizedBox(height: 16),

                // Today's matches
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'TODAY\'S MATCHES',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
                if (today.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: today.map((m) => MatchCard(match: m)).toList(),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassBoxDecoration(context: context),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 36, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No matches scheduled for today',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Upcoming Matches
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UPCOMING MATCHES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
                if (upcoming.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: upcoming.map((m) => MatchCard(match: m)).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'No upcoming matches found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
