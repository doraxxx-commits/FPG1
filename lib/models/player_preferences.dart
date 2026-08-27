class PlayerPreferences {
  int minutesExpectation;
  int preferredClubLevel;
  int foreignMoveWillingness;
  int wagePriority;
  int loyaltyToCurrentClub;
  String preferredRole;

  PlayerPreferences({
    this.minutesExpectation = 60,
    this.preferredClubLevel = 50,
    this.foreignMoveWillingness = 50,
    this.wagePriority = 50,
    this.loyaltyToCurrentClub = 50,
    this.preferredRole = 'rotation',
  });

  Map<String, dynamic> toJson() => {
    'minutesExpectation': minutesExpectation,
    'preferredClubLevel': preferredClubLevel,
    'foreignMoveWillingness': foreignMoveWillingness,
    'wagePriority': wagePriority,
    'loyaltyToCurrentClub': loyaltyToCurrentClub,
    'preferredRole': preferredRole,
  };

  factory PlayerPreferences.fromJson(Map<String, dynamic>? j) => PlayerPreferences(
    minutesExpectation: j?['minutesExpectation'] ?? 60,
    preferredClubLevel: j?['preferredClubLevel'] ?? 50,
    foreignMoveWillingness: j?['foreignMoveWillingness'] ?? 50,
    wagePriority: j?['wagePriority'] ?? 50,
    loyaltyToCurrentClub: j?['loyaltyToCurrentClub'] ?? 50,
    preferredRole: j?['preferredRole'] ?? 'rotation',
  );
}
