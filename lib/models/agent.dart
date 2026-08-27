class Agent {
  final String id;
  final String name;
  int reputation;
  int negotiationSkill;
  int marketInfluence;
  int loyalty;
  int wageDemand;
  bool aggressiveInNegotiations;

  Agent({
    required this.id,
    required this.name,
    this.reputation = 50,
    this.negotiationSkill = 50,
    this.marketInfluence = 50,
    this.loyalty = 50,
    this.wageDemand = 10,
    this.aggressiveInNegotiations = false,
  });
}
