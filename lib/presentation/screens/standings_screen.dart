import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/standings_provider.dart';
import '../../core/constants/theme.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StandingsProvider>(
      builder: (context, standingsProv, _) {
        final groups = standingsProv.groupNames;

        if (groups.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Standings')),
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          );
        }

        return DefaultTabController(
          length: groups.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Group Standings'),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                labelColor: Theme.of(context).colorScheme.secondary,
                unselectedLabelColor: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                tabs: groups
                    .map((g) => Tab(text: g.replaceAll('Group ', 'Group ')))
                    .toList(),
              ),
            ),
            body: TabBarView(
              children: groups.map((groupName) {
                final standings = standingsProv.groupStandings[groupName] ?? [];
                return _buildGroupTable(context, standings);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupTable(BuildContext context, List<TeamStanding> standings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Table Card
        Container(
          decoration: AppTheme.glassBoxDecoration(context: context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DataTable(
              columnSpacing: 6,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(
                isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.02),
              ),
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 25,
                    child: Text(
                      'Pos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Team',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 14,
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 14,
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 14,
                    child: Text(
                      'D',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 14,
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 20,
                    child: Text(
                      'GD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 24,
                    child: Text(
                      'PTS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              rows: List.generate(standings.length, (idx) {
                final standing = standings[idx];
                final pos = idx + 1;
                // Highlight top 2 as qualifying spots ONLY when group finished
                final totalPlayed = standings.fold<int>(0, (sum, t) => sum + t.played);
                final isGroupFinished = totalPlayed >= 12;
                final isQualifyingSpot = isGroupFinished && (pos <= 2);

                return DataRow(
                  cells: [
                    // Pos
                    DataCell(
                      Row(
                        children: [
                          if (isQualifyingSpot)
                            Container(
                              width: 3,
                              height: 18,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          else
                            const SizedBox(width: 9),
                          Text(
                            '$pos',
                            style: TextStyle(
                              fontWeight: isQualifyingSpot
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                              color: isQualifyingSpot
                                  ? (isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Team Name & Flag
                    DataCell(
                      Row(
                        children: [
                          Text(
                            standing.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              standing.teamName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isQualifyingSpot
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Played
                    DataCell(
                      SizedBox(
                        width: 14,
                        child: Text(
                          '${standing.played}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Won
                    DataCell(
                      SizedBox(
                        width: 14,
                        child: Text(
                          '${standing.won}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Drawn
                    DataCell(
                      SizedBox(
                        width: 14,
                        child: Text(
                          '${standing.drawn}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Lost
                    DataCell(
                      SizedBox(
                        width: 14,
                        child: Text(
                          '${standing.lost}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // GD
                    DataCell(
                      SizedBox(
                        width: 20,
                        child: Text(
                          standing.goalDifference > 0
                              ? '+${standing.goalDifference}'
                              : '${standing.goalDifference}',
                          style: TextStyle(
                            fontSize: 12,
                            color: standing.goalDifference > 0
                                ? Colors.greenAccent
                                : standing.goalDifference < 0
                                ? Colors.redAccent
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Points
                    DataCell(
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${standing.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Qualification legend & Acronyms Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassBoxDecoration(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '= Qualified next round',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'P = Matches Played',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'W = Wins',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'D = Draws',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'L = Loss',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'GD = Goal Difference',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'Pts = Points',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
