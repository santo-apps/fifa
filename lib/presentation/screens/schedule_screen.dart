import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/match_model.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/match_card.dart';
import '../../core/constants/theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Schedule'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            tabs: const [
              Tab(text: 'Fixtures'),
              Tab(text: 'Results'),
            ],
          ),
        ),
        body: Consumer<ScheduleProvider>(
          builder: (context, scheduleProv, _) {
            if (scheduleProv.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
              );
            }

            final allFiltered = scheduleProv.filteredMatches;
            final fixtures = allFiltered.where((m) => m.status != 'completed').toList();
            final results = allFiltered.where((m) => m.status == 'completed').toList();
            // Sort completed results descending (most recent completed matches first)
            results.sort((a, b) => b.dateTime.compareTo(a.dateTime));

            final stages = scheduleProv.allStages;
            final groups = scheduleProv.allGroups;
            final teams = scheduleProv.allTeams;

            return Column(
              children: [
                // Filter chips scrollable bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Stage Filter
                      _buildFilterChip(
                        context: context,
                        label: scheduleProv.selectedStage.isEmpty
                            ? 'All Stages'
                            : scheduleProv.selectedStage,
                        isActive: scheduleProv.selectedStage.isNotEmpty,
                        onTap: () => _showStagePicker(context, scheduleProv, stages),
                      ),
                      const SizedBox(width: 8),

                      // Group Filter
                      _buildFilterChip(
                        context: context,
                        label: scheduleProv.selectedGroup.isEmpty
                            ? 'All Groups'
                            : scheduleProv.selectedGroup,
                        isActive: scheduleProv.selectedGroup.isNotEmpty,
                        onTap: () => _showGroupPicker(context, scheduleProv, groups),
                      ),
                      const SizedBox(width: 8),

                      // Team Filter
                      _buildFilterChip(
                        context: context,
                        label: scheduleProv.selectedTeam.isEmpty
                            ? 'Filter by Team'
                            : scheduleProv.selectedTeam,
                        isActive: scheduleProv.selectedTeam.isNotEmpty,
                        onTap: () => _showTeamPicker(context, scheduleProv, teams),
                      ),
                      const SizedBox(width: 8),

                      // Date Filter
                      _buildFilterChip(
                        context: context,
                        label: scheduleProv.selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM d').format(scheduleProv.selectedDate!),
                        isActive: scheduleProv.selectedDate != null,
                        onTap: () => _showDatePicker(context, scheduleProv),
                      ),
                    ],
                  ),
                ),

                // Active filter indicators & Reset button
                if (scheduleProv.selectedStage.isNotEmpty ||
                    scheduleProv.selectedGroup.isNotEmpty ||
                    scheduleProv.selectedTeam.isNotEmpty ||
                    scheduleProv.selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Found ${allFiltered.length} matches',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: scheduleProv.clearFilters,
                          child: Row(
                            children: [
                              Icon(Icons.clear_all_rounded, size: 16, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Clear Filters',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // TabBarView showing Fixtures or Results
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMatchesListSection(context, fixtures, scheduleProv),
                      _buildMatchesListSection(context, results, scheduleProv),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchesListSection(
      BuildContext context, List<MatchModel> matches, ScheduleProvider scheduleProv) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No matches matches your filters',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: scheduleProv.clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, idx) {
        return MatchCard(match: matches[idx]);
      },
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.15)
              : isDark
                  ? AppTheme.darkCardBg
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.secondary
                : isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.secondary
                    : isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive
                  ? Theme.of(context).colorScheme.secondary
                  : isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheets to select filters
  void _showStagePicker(BuildContext context, ScheduleProvider prov, List<String> stages) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Tournament Stage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('All Stages'),
                selected: prov.selectedStage.isEmpty,
                onTap: () {
                  prov.setSelectedStage('');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: stages.length,
                  itemBuilder: (context, idx) {
                    final stage = stages[idx];
                    return ListTile(
                      title: Text(stage),
                      selected: prov.selectedStage == stage,
                      onTap: () {
                        prov.setSelectedStage(stage);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGroupPicker(BuildContext context, ScheduleProvider prov, List<String> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Group Stage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('All Groups'),
                selected: prov.selectedGroup.isEmpty,
                onTap: () {
                  prov.setSelectedGroup('');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, idx) {
                    final group = groups[idx];
                    return ListTile(
                      title: Text(group),
                      selected: prov.selectedGroup == group,
                      onTap: () {
                        prov.setSelectedGroup(group);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTeamPicker(BuildContext context, ScheduleProvider prov, List<String> teams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Clear Team Filter'),
                selected: prov.selectedTeam.isEmpty,
                onTap: () {
                  prov.setSelectedTeam('');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, idx) {
                    final team = teams[idx];
                    return ListTile(
                      title: Text(team),
                      selected: prov.selectedTeam == team,
                      onTap: () {
                        prov.setSelectedTeam(team);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDatePicker(BuildContext context, ScheduleProvider prov) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: prov.selectedDate ?? DateTime(2026, 6, 11),
      firstDate: DateTime(2026, 6, 1),
      lastDate: DateTime(2026, 7, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      prov.setSelectedDate(picked);
    }
  }
}
