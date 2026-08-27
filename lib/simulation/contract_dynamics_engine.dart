import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/contract_negotiation.dart';

/// V18.7 — dynamiczne kontrakty i pensje.
///
/// Kontrakt jest wynikiem negocjacji trzech stron:
/// zawodnik + klub + agent. Fame/Reputation/Marketability nie są kosmetyką:
/// zmieniają oczekiwania płacowe, bonusy, długość umowy i klauzulę.
class ContractDynamicsEngine {
  final Random _random;
  final Map<String, ContractNegotiation> active = {};

  ContractDynamicsEngine({Random? random}) : _random = random ?? Random();

  List<String> processDay({
    required List<Club> clubs,
    required List<Player> players,
    required int absoluteDay,
  }) {
    final logs = <String>[];

    // Kontrakty nie powinny negocjować się codziennie. Tygodniowy rytm daje
    // miejsce na rozwój historii i nie spamuje świata.
    if (absoluteDay % 7 != 0) return logs;

    for (final player in players) {
      if (player.clubId == null || player.injured) continue;
      if (player.contractYearsRemaining > 2) continue;

      final club = clubs.where((c) => c.id == player.clubId).firstOrNull;
      if (club == null || !_wantsRenewal(club, player)) continue;

      final id = '${club.id}::${player.id}';
      final negotiation = active.putIfAbsent(id, () => _open(club, player));

      negotiation.round++;
      _recalculateExpectations(club, player, negotiation);

      // Im większa sława, reputacja i siła agenta, tym mniej zawodnik
      // akceptuje "klubową stawkę".
      final wageGap = negotiation.demandedWage - negotiation.offeredWage;
      final bonusGap =
          (negotiation.demandedAppearanceBonus - negotiation.offeredAppearanceBonus).abs() +
          (negotiation.demandedGoalBonus - negotiation.offeredGoalBonus).abs();

      final wageTolerance = max(
        2,
        (negotiation.demandedWage * (.045 + player.reputation / 5000)).round(),
      );
      final budgetOk = club.budget >= negotiation.demandedWage * 52;

      if (wageGap.abs() <= wageTolerance &&
          bonusGap <= max(500, negotiation.demandedWage ~/ 3) &&
          budgetOk) {
        _accept(player, negotiation);
        logs.add(
          'KONTRAKT: ${player.name} podpisał ${negotiation.demandedYears}-letnią umowę z ${club.name}. '
          'Pensja: ${player.weeklyWage.round()}/tydz.',
        );
        active.remove(id);
        continue;
      }

      // Agent/rozpoznawalność zwiększają wymagania, ale także zdolność do
      // wynegocjowania lepszej oferty po stronie klubu.
      final agentPower = player.agentInfluence +
          player.agentAttention ~/ 2 +
          player.reputation ~/ 3;
      final negotiationProgress = 2 + agentPower ~/ 35;

      if (negotiation.round < 6) {
        negotiation.offeredWage += max(
          1,
          ((negotiation.demandedWage - negotiation.offeredWage) /
                  (7 - negotiationProgress.clamp(0, 4)))
              .round(),
        );
        negotiation.offeredAppearanceBonus +=
            max(0, (negotiation.demandedAppearanceBonus -
                    negotiation.offeredAppearanceBonus) ~/
                3);
        negotiation.offeredGoalBonus +=
            max(0, (negotiation.demandedGoalBonus -
                    negotiation.offeredGoalBonus) ~/
                3);
        negotiation.offeredYears =
            min(negotiation.demandedYears, negotiation.offeredYears + 1);
        negotiation.patience--;

        // Bardzo medialny zawodnik może zerwać rozmowy szybciej, gdy klub
        // próbuje utrzymać starą pensję.
        if (player.fame >= 80 &&
            player.reputation >= 70 &&
            negotiation.round >= 4 &&
            negotiation.offeredWage < negotiation.demandedWage * .88) {
          negotiation.stage = 'rejected';
          player.happiness = max(15, player.happiness - 4);
          player.transferRequest = true;
          logs.add(
            'KONTRAKT: ${player.name} uznał ofertę ${club.name} za zbyt niską. '
            'Agent rozważa rynek transferowy.',
          );
          active.remove(id);
        } else {
          negotiation.stage = 'counter';
        }
      } else {
        negotiation.stage = 'rejected';
        player.happiness = max(20, player.happiness - 5);
        if (player.contractYearsRemaining <= 1 && player.fame >= 65) {
          player.transferRequest = true;
        }
        logs.add(
          'KONTRAKT: ${player.name} i ${club.name} nie osiągnęli porozumienia.',
        );
        active.remove(id);
      }
    }
    return logs;
  }

  ContractNegotiation _open(Club club, Player p) {
    final famePremium = p.fame * .0025;
    final reputationPremium = max(0, p.reputation - 50) * .003;
    final marketingPremium = p.marketingValue * .0015;
    final agentPremium = p.agentInfluence * .0015;
    final performancePremium = max(0, p.form - 60) * .002;

    final multiplier = 1 +
        famePremium +
        reputationPremium +
        marketingPremium +
        agentPremium +
        performancePremium;

    final demandedWage =
        max(p.weeklyWage.round() + 1, (p.weeklyWage * multiplier).round());

    final demandedYears = p.age >= 31
        ? (p.fame >= 70 ? 2 : 1)
        : p.age <= 23
            ? 4
            : 3;

    final role = _desiredRole(club, p);
    final appearance = max(p.appearanceBonus, (demandedWage * .18).round());
    final goal = max(p.goalBonus, (demandedWage * .34).round());

    return ContractNegotiation(
      id: '${club.id}::${p.id}',
      clubId: club.id,
      playerId: p.id,
      offeredWage: p.weeklyWage.round(),
      demandedWage: demandedWage,
      offeredYears: p.age >= 30 ? 1 : 2,
      demandedYears: demandedYears,
      offeredAppearanceBonus: p.appearanceBonus,
      demandedAppearanceBonus: appearance,
      offeredGoalBonus: p.goalBonus,
      demandedGoalBonus: goal,
      offeredReleaseClause: p.releaseClause,
      demandedReleaseClause: _releaseClause(club, p),
      round: 1,
      patience: 5,
    );
  }

  void _recalculateExpectations(
      Club club, Player p, ContractNegotiation n) {
    final fameFactor = p.fame >= 80 ? 1.10 : p.fame >= 60 ? 1.05 : 1.0;
    final reputationFactor = p.reputation >= 80 ? 1.08 : 1.0;
    final formFactor = p.form >= 80 ? 1.06 : p.form <= 45 ? .96 : 1.0;
    final agentFactor = 1 + p.agentInfluence / 2500;

    final target = max(
      p.weeklyWage.round(),
      (p.weeklyWage * fameFactor * reputationFactor * formFactor * agentFactor)
          .round(),
    );

    n.demandedWage = max(n.demandedWage, target);
    n.demandedAppearanceBonus =
        max(n.demandedAppearanceBonus, (target * .18).round());
    n.demandedGoalBonus =
        max(n.demandedGoalBonus, (target * .34).round());
    n.demandedReleaseClause = max(
      n.demandedReleaseClause,
      _releaseClause(club, p),
    );
  }

  void _accept(Player p, ContractNegotiation n) {
    p.weeklyWage = n.demandedWage.toDouble();
    p.wageExpectation = n.demandedWage;
    p.contractYearsRemaining = n.demandedYears;
    p.appearanceBonus = n.demandedAppearanceBonus;
    p.goalBonus = n.demandedGoalBonus;
    p.releaseClause = n.demandedReleaseClause;
    p.contractRole = _desiredRoleFromNegotiation(p, n);
    p.happiness = min(100, p.happiness + 8);
    p.transferRequest = false;
  }

  String _desiredRole(Club club, Player p) {
    if (p.overall >= club.overall + 2 || p.fame >= 75) return 'important';
    if (p.overall >= club.minimumSigningOverall) return 'rotation';
    return 'squad';
  }

  String _desiredRoleFromNegotiation(Player p, ContractNegotiation n) {
    if (n.stage == 'important') return 'important';
    if (p.fame >= 75 || p.overall >= 80) return 'important';
    return p.contractRole == 'important' ? 'important' : 'rotation';
  }

  bool _wantsRenewal(Club club, Player p) {
    if (club.financialHealth < 15 &&
        p.weeklyWage > max(1, club.budget ~/ 900)) return false;
    if (p.age >= 34 && p.overall < club.minimumSigningOverall) return false;
    if (p.transferRequest && p.fame < 50 && p.reputation < 55) return false;

    return p.overall >= club.minimumSigningOverall - 10 ||
        p.potential >= 82 ||
        p.contractRole == 'important' ||
        p.fame >= 65;
  }

  double _releaseClause(Club club, Player p) {
    final fameMultiplier = 1 + p.fame / 180;
    final reputationMultiplier = 1 + p.reputation / 300;
    final clubMultiplier = 1 + club.reputation / 250;
    return max(
      p.value * fameMultiplier * reputationMultiplier * clubMultiplier,
      p.value * 1.8,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active.map((k, n) => MapEntry(k, {
              'id': n.id,
              'clubId': n.clubId,
              'playerId': n.playerId,
              'round': n.round,
              'offeredWage': n.offeredWage,
              'demandedWage': n.demandedWage,
              'offeredYears': n.offeredYears,
              'demandedYears': n.demandedYears,
              'offeredAppearanceBonus': n.offeredAppearanceBonus,
              'demandedAppearanceBonus': n.demandedAppearanceBonus,
              'offeredGoalBonus': n.offeredGoalBonus,
              'demandedGoalBonus': n.demandedGoalBonus,
              'offeredReleaseClause': n.offeredReleaseClause,
              'demandedReleaseClause': n.demandedReleaseClause,
              'stage': n.stage,
              'patience': n.patience,
            })),
      };

  void restoreFromJson(Map<String, dynamic>? json) {
    active.clear();
    if (json == null || json['active'] is! Map) return;
    for (final entry in (json['active'] as Map).entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final n = ContractNegotiation(
        id: raw['id'] ?? entry.key.toString(),
        clubId: raw['clubId'] ?? '',
        playerId: raw['playerId'] ?? '',
        round: raw['round'] ?? 1,
        offeredWage: raw['offeredWage'] ?? 0,
        demandedWage: raw['demandedWage'] ?? 0,
        offeredYears: raw['offeredYears'] ?? 1,
        demandedYears: raw['demandedYears'] ?? 1,
        offeredAppearanceBonus: raw['offeredAppearanceBonus'] ?? 0,
        demandedAppearanceBonus: raw['demandedAppearanceBonus'] ?? 0,
        offeredGoalBonus: raw['offeredGoalBonus'] ?? 0,
        demandedGoalBonus: raw['demandedGoalBonus'] ?? 0,
        offeredReleaseClause: (raw['offeredReleaseClause'] ?? 0).toDouble(),
        demandedReleaseClause: (raw['demandedReleaseClause'] ?? 0).toDouble(),
        stage: raw['stage'] ?? 'counter',
        patience: raw['patience'] ?? 4,
      );
      active[entry.key.toString()] = n;
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
