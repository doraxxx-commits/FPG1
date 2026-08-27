import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/contract_negotiation.dart';
import 'agent_engine.dart';

/// Negocjacje przedłużenia kontraktu. Klub, zawodnik i agent mają własne
/// interesy, a wynik zależy od wielu rund, nie od jednego rzutu.
class ContractNegotiationEngine {
  final Random _random;
  final Map<String, ContractNegotiation> active = {};

  ContractNegotiationEngine({Random? random}) : _random = random ?? Random();

  List<ContractNegotiation> activeForPlayer(String playerId) =>
      active.values.where((n) => n.playerId == playerId).toList();

  bool counterForPlayer(String negotiationId) {
    final n = active[negotiationId];
    if (n == null || n.stage == 'accepted' || n.stage == 'rejected') return false;
    n.offeredWage += max(1, (n.demandedWage - n.offeredWage) ~/ 4);
    n.offeredAppearanceBonus += max(0, (n.demandedAppearanceBonus - n.offeredAppearanceBonus) ~/ 4);
    n.offeredGoalBonus += max(0, (n.demandedGoalBonus - n.offeredGoalBonus) ~/ 4);
    n.offeredYears = max(n.offeredYears, min(n.demandedYears, n.offeredYears + 1));
    n.round++;
    n.patience = max(0, n.patience - 1);
    n.stage = 'counter';
    return true;
  }

  bool acceptForPlayer(String negotiationId, List<Player> players, List<Club> clubs) {
    final n = active[negotiationId];
    if (n == null || n.stage == 'accepted' || n.stage == 'rejected') return false;
    final p = players.where((x) => x.id == n.playerId).firstOrNull;
    final club = clubs.where((x) => x.id == n.clubId).firstOrNull;
    if (p == null || club == null || club.budget < n.offeredWage * 52) return false;
    p.weeklyWage = n.offeredWage.toDouble();
    p.contractYearsRemaining = n.offeredYears;
    p.appearanceBonus = n.offeredAppearanceBonus;
    p.goalBonus = n.offeredGoalBonus;
    p.releaseClause = n.offeredReleaseClause > 0 ? n.offeredReleaseClause : p.releaseClause;
    p.wageExpectation = n.offeredWage;
    n.stage = 'accepted';
    active.remove(negotiationId);
    return true;
  }

  bool rejectForPlayer(String negotiationId, List<Player> players) {
    final n = active[negotiationId];
    if (n == null) return false;
    final p = players.where((x) => x.id == n.playerId).firstOrNull;
    if (p != null) p.happiness = max(10, p.happiness - 5);
    n.stage = 'rejected';
    active.remove(negotiationId);
    return true;
  }

  List<String> process({
    required List<Club> clubs,
    required List<Player> players,
    required AgentEngine agentEngine,
  }) {
    final logs = <String>[];
    for (final player in players.where((p) => p.clubId != null && p.contractYearsRemaining <= 1)) {
      final club = clubs.where((c) => c.id == player.clubId).firstOrNull;
      if (club == null) continue;
      if (! _wantsNegotiation(club, player)) continue;

      final agent = player.agentId == null ? null : agentEngine.agentById(player.agentId!);
      final id = '${club.id}::${player.id}';
      final n = active.putIfAbsent(id, () {
        final demanded = max(player.wageExpectation, (player.weeklyWage * (1.08 + (agent?.wageDemand ?? 10) / 1000)).round());
        return ContractNegotiation(
          id: id,
          clubId: club.id,
          playerId: player.id,
          offeredWage: player.weeklyWage.round(),
          demandedWage: demanded,
          offeredYears: player.age >= 30 ? 1 : 2,
          demandedYears: player.age >= 30 ? 1 : 3,
          offeredAppearanceBonus: player.appearanceBonus,
          demandedAppearanceBonus: max(player.appearanceBonus, (demanded * .18).round()),
          offeredGoalBonus: player.goalBonus,
          demandedGoalBonus: max(player.goalBonus, (demanded * .35).round()),
          offeredReleaseClause: player.releaseClause,
          demandedReleaseClause: player.value * (2.0 + player.agentInfluence / 100.0),
        );
      });

      n.round++;
      final wageGap = (n.demandedWage - n.offeredWage).abs();
      final bonusGap = (n.demandedAppearanceBonus - n.offeredAppearanceBonus).abs() +
          (n.demandedGoalBonus - n.offeredGoalBonus).abs();
      final acceptableWage = max(1, (n.demandedWage * .07).round());
      final acceptableBonus = max(500, (n.demandedWage * .2).round());

      if (wageGap <= acceptableWage && bonusGap <= acceptableBonus && club.budget >= n.demandedWage * 52) {
        player.weeklyWage = n.demandedWage.toDouble();
        player.contractYearsRemaining = n.demandedYears;
        player.appearanceBonus = n.demandedAppearanceBonus;
        player.goalBonus = n.demandedGoalBonus;
        player.releaseClause = n.demandedReleaseClause;
        player.contractRole = player.overall >= club.overall ? 'important' : player.contractRole;
        n.stage = 'accepted';
        active.remove(id);
        logs.add('KONTRAKT: ${player.name} przedłużył umowę z ${club.name}.');
        continue;
      }

      if (n.round >= 5 || n.patience <= 0) {
        n.stage = 'rejected';
        active.remove(id);
        player.happiness = max(20, player.happiness - 6);
        logs.add('KONTRAKT: negocjacje ${player.name} z ${club.name} zakończyły się bez porozumienia.');
        continue;
      }

      final step = max(1, (n.demandedWage - n.offeredWage) ~/ 3);
      n.offeredWage += step;
      n.offeredAppearanceBonus += max(0, (n.demandedAppearanceBonus - n.offeredAppearanceBonus) ~/ 3);
      n.offeredGoalBonus += max(0, (n.demandedGoalBonus - n.offeredGoalBonus) ~/ 3);
      n.offeredYears = max(n.offeredYears, min(n.demandedYears, n.offeredYears + 1));
      n.patience--;
      n.stage = 'counter';
    }
    return logs;
  }

  bool _wantsNegotiation(Club club, Player player) {
    if (club.financialHealth < 18 && player.weeklyWage > club.budget / 1000) return false;
    if (player.age >= 32 && player.overall < club.minimumSigningOverall - 5) return false;
    return player.overall >= club.minimumSigningOverall - 8 || player.potential >= 80 || player.contractRole == 'important';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
