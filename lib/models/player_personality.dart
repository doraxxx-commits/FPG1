class PlayerPersonality {
  int professionalism;
  int ambition;
  int loyalty;
  int adaptability;
  int discipline;

  PlayerPersonality({
    this.professionalism = 60,
    this.ambition = 60,
    this.loyalty = 60,
    this.adaptability = 60,
    this.discipline = 60,
  });

  Map<String, dynamic> toJson() => {
    'professionalism': professionalism,
    'ambition': ambition,
    'loyalty': loyalty,
    'adaptability': adaptability,
    'discipline': discipline,
  };

  factory PlayerPersonality.fromJson(Map<String, dynamic>? j) => PlayerPersonality(
    professionalism: j?['professionalism'] ?? 60,
    ambition: j?['ambition'] ?? 60,
    loyalty: j?['loyalty'] ?? 60,
    adaptability: j?['adaptability'] ?? 60,
    discipline: j?['discipline'] ?? 60,
  );
}
