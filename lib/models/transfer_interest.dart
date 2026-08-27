/// Trwałe zainteresowanie klubu zawodnikiem. Nie jest jeszcze transferem —
/// przechodzi przez scouting, ofertę i negocjacje.
class TransferInterest {
  final String id;
  final String clubId;
  final String playerId;
  int score;
  String stage; // scouting, serious, offer, negotiation, cooling
  int daysActive;
  int lastContactDay;
  bool playerAware;
  int awarenessDay;
  String playerDecision;

  // V18.6: wpływ agenta i jakość potencjalnej oferty są pamięcią rynku.
  int agentInfluence;
  int clubFit;
  int offerQuality;
  bool agentBacked;
  int lastAgentActionDay;

  TransferInterest({
    required this.id,
    required this.clubId,
    required this.playerId,
    this.score = 25,
    this.stage = 'scouting',
    this.daysActive = 0,
    this.lastContactDay = 0,
    this.playerAware = false,
    this.awarenessDay = 0,
    this.playerDecision = 'pending',
    this.agentInfluence = 0,
    this.clubFit = 0,
    this.offerQuality = 0,
    this.agentBacked = false,
    this.lastAgentActionDay = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'clubId': clubId, 'playerId': playerId,
    'score': score, 'stage': stage, 'daysActive': daysActive,
    'lastContactDay': lastContactDay, 'playerAware': playerAware,
    'awarenessDay': awarenessDay, 'playerDecision': playerDecision,
    'agentInfluence': agentInfluence, 'clubFit': clubFit,
    'offerQuality': offerQuality, 'agentBacked': agentBacked,
    'lastAgentActionDay': lastAgentActionDay,
  };

  factory TransferInterest.fromJson(Map<String, dynamic> j) => TransferInterest(
    id: j['id'] ?? '', clubId: j['clubId'] ?? '', playerId: j['playerId'] ?? '',
    score: j['score'] ?? 25, stage: j['stage'] ?? 'scouting',
    daysActive: j['daysActive'] ?? 0, lastContactDay: j['lastContactDay'] ?? 0,
    playerAware: j['playerAware'] ?? false, awarenessDay: j['awarenessDay'] ?? 0,
    playerDecision: j['playerDecision'] ?? 'pending',
    agentInfluence: j['agentInfluence'] ?? 0, clubFit: j['clubFit'] ?? 0,
    offerQuality: j['offerQuality'] ?? 0, agentBacked: j['agentBacked'] ?? false,
    lastAgentActionDay: j['lastAgentActionDay'] ?? 0,
  );
}
