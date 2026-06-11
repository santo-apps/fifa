import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/match_card.dart';
import '../../core/constants/theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          tabs: const [
            Tab(text: 'Bookmarked Matches'),
            Tab(text: 'Favorite Teams'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Bookmarked Matches
          const _BookmarkedMatchesTab(),

          // Tab 2: Favorite Teams and Personalized Schedule
          const _FavoriteTeamsTab(),
        ],
      ),
    );
  }
}

class _BookmarkedMatchesTab extends StatelessWidget {
  const _BookmarkedMatchesTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ScheduleProvider, FavoritesProvider>(
      builder: (context, scheduleProv, favProv, _) {
        final bookmarkedIds = favProv.bookmarkedMatches;
        final matches = scheduleProv.matches.where((m) => bookmarkedIds.contains(m.id)).toList();

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  size: 64,
                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No bookmarked matches yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tap the star icon on any match card to bookmark it and receive reminders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: matches.length,
          itemBuilder: (context, idx) {
            return MatchCard(match: matches[idx]);
          },
        );
      },
    );
  }
}

class _FavoriteTeamsTab extends StatelessWidget {
  const _FavoriteTeamsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ScheduleProvider, FavoritesProvider>(
      builder: (context, scheduleProv, favProv, _) {
        final allTeams = scheduleProv.allTeams;
        final favoriteTeams = favProv.favoriteTeams;

        // Filter schedule matches involving favorite teams
        final personalMatches = scheduleProv.matches.where((m) {
          return favProv.isTeamFavorite(m.homeTeam) || favProv.isTeamFavorite(m.awayTeam);
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Favorites selection box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SELECT YOUR TEAMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // horizontal scrolling selection of all teams
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allTeams.length,
                itemBuilder: (context, idx) {
                  final team = allTeams[idx];
                  final isFav = favProv.isTeamFavorite(team);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(team),
                      selected: isFav,
                      selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                      checkmarkColor: Theme.of(context).colorScheme.secondary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isFav ? FontWeight.bold : FontWeight.normal,
                        color: isFav
                            ? Theme.of(context).colorScheme.secondary
                            : isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                      ),
                      backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
                      side: BorderSide(
                        color: isFav
                            ? Theme.of(context).colorScheme.secondary
                            : isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                      ),
                      onSelected: (_) => favProv.toggleFavoriteTeam(team),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Personalized schedule header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'PERSONALIZED SCHEDULE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (favoriteTeams.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassBoxDecoration(context: context),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.flag_outlined, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No favorite teams selected',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select teams above to filter schedule to matches involving them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (personalMatches.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No matches scheduled for your teams yet.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: personalMatches.map((m) => MatchCard(match: m)).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}
