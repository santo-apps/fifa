import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/match_card.dart';
import '../../core/constants/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any previous query when opening search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search teams, venues, or cities...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<ScheduleProvider>(context, listen: false).setSearchQuery('');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {}); // refresh suffixIcon visibility
            Provider.of<ScheduleProvider>(context, listen: false).setSearchQuery(val);
          },
        ),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProv, _) {
          final results = scheduleProv.filteredMatches;

          if (scheduleProv.searchQuery.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Search for World Cup matches',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No matches found for "${scheduleProv.searchQuery}"',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: results.length,
            itemBuilder: (context, idx) {
              return MatchCard(match: results[idx]);
            },
          );
        },
      ),
    );
  }
}
