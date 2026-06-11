import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<String> _favoriteTeams = [];
  List<String> _bookmarkedMatches = [];

  FavoritesProvider() {
    _favoriteTeams = StorageService.getFavoriteTeams();
    _bookmarkedMatches = StorageService.getBookmarkedMatches();
  }

  List<String> get favoriteTeams => _favoriteTeams;
  List<String> get bookmarkedMatches => _bookmarkedMatches;

  bool isTeamFavorite(String teamName) {
    return _favoriteTeams.contains(teamName.trim().toLowerCase());
  }

  bool isMatchBookmarked(String matchId) {
    return _bookmarkedMatches.contains(matchId);
  }

  Future<void> toggleFavoriteTeam(String teamName) async {
    final cleanName = teamName.trim().toLowerCase();
    if (_favoriteTeams.contains(cleanName)) {
      _favoriteTeams.remove(cleanName);
    } else {
      _favoriteTeams.add(cleanName);
    }
    await StorageService.saveFavoriteTeams(_favoriteTeams);
    notifyListeners();
  }

  Future<void> toggleBookmarkMatch(String matchId) async {
    if (_bookmarkedMatches.contains(matchId)) {
      _bookmarkedMatches.remove(matchId);
    } else {
      _bookmarkedMatches.add(matchId);
    }
    await StorageService.saveBookmarkedMatches(_bookmarkedMatches);
    notifyListeners();
  }
}
