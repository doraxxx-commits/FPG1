import 'match_result.dart';

class Fixture {
  final int round;
  final String homeClubId;
  final String awayClubId;

  final int year;
  final int month;
  final int day;

  bool played;
  int? homeGoals;
  int? awayGoals;
  Map<String, dynamic>? resultSnapshot;

  Fixture({
    required this.round,
    required this.homeClubId,
    required this.awayClubId,
    required this.year,
    required this.month,
    required this.day,
    this.played = false,
    this.homeGoals,
    this.awayGoals,
    this.resultSnapshot,
  });
  MatchResult? get storedResult {
    final snapshot = resultSnapshot;
    if (snapshot == null) return null;
    try {
      return MatchResult.fromJson(snapshot);
    } catch (_) {
      return null;
    }
  }

  void storeResult(MatchResult result) {
    resultSnapshot = result.toJson();
  }
}
