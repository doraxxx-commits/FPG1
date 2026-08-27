import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../core/fpg_theme.dart';
import '../models/club.dart';
import '../models/transfer_negotiation.dart';

/// V18.9 — Transfer Market UI & Player Decisions.
///
/// Ekran nie generuje już fikcyjnych ofert. Pokazuje negocjacje pochodzące
/// z tego samego World Simulation, w którym działają kluby AI.
class TransfersScreen extends StatefulWidget {
  final GameEngine engine;
  const TransfersScreen({super.key, required this.engine});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  GameEngine get engine => widget.engine;

  List<TransferNegotiation> get _negotiations {
    final player = engine.careerPlayer;
    if (player == null) return const [];
    return engine.worldEngine.worldSimulation4Engine.transferNegotiationV2Engine
        .activeForPlayer(player.id);
  }

  Club? _club(String id) => engine.clubs.where((c) => c.id == id).firstOrNull;

  void _requestTransfer(dynamic player) {
    if (!engine.summerTransferWindow && !engine.winterTransferWindow) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfery są obecnie zamknięte.')));
      return;
    }
    final world = engine.worldEngine.worldSimulation4Engine;
    final created = world.transferInterestEngine.requestTransfer(
      clubs: engine.clubs,
      player: engine.careerPlayer!,
      absoluteDay: engine.currentAbsoluteDay,
      agentEngine: world.agentEngine,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(created.isEmpty ? 'Nie znaleziono odpowiednich klubów.' : 'Agent rozpoczął rozmowy z ${created.length} klubami.')),
    );
  }

  void _decision(TransferNegotiation n, String decision) {
    final ok = engine.worldEngine.worldSimulation4Engine.transferNegotiationV2Engine
        .playerDecision(n.id, decision);
    if (!ok) return;
    setState(() {});
    final label = decision == 'accept'
        ? 'Akceptowałeś warunki zawodnika.'
        : decision == 'negotiate'
            ? 'Wysłano kontrofertę agenta.'
            : 'Odrzuciłeś ofertę.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;
    final negotiations = _negotiations;
    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(
        title: const Text('Rynek Transferowy'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
        ],
      ),
      body: player == null
          ? const Center(child: Text('Brak aktywnej kariery.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _playerHeader(player),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _requestTransfer(player),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('POPROŚ O TRANSFER'),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('AKTYWNE NEGOCJACJE', style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Colors.white70)),
                const SizedBox(height: 10),
                if (negotiations.isEmpty) _empty(),
                ...negotiations.map(_negotiationCard),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: const [
                      Icon(Icons.info_outline, color: FPGTheme.accent),
                      SizedBox(width: 12),
                      Expanded(child: Text('Akceptacja oznacza zgodę zawodnika na warunki. Transfer dojdzie do skutku dopiero, gdy klub kupujący i sprzedający domkną swoje warunki.')),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _playerHeader(dynamic player) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(player.fullName, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('OVR ${player.overall} • Fame ${player.fame} • Reputation ${player.reputation}', style: const TextStyle(color: FPGTheme.muted)),
              ])),
              Text('${((player.contract?.marketValue ?? 0) / 1000000).toStringAsFixed(1)} mln €', style: const TextStyle(color: FPGTheme.accent, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _metric('PENSJA', '${player.contract?.weeklySalary.toStringAsFixed(0) ?? 0} €')),
              const SizedBox(width: 8),
              Expanded(child: _metric('MARKETING', '${player.marketability}')),
              const SizedBox(width: 8),
              Expanded(child: _metric('AGENT', '${player.agentInfluence}')),
            ]),
          ]),
        ),
      );

  Widget _negotiationCard(TransferNegotiation n) {
    final buyer = _club(n.buyerClubId);
    final seller = _club(n.sellerClubId);
    final decision = n.playerDecision;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(buyer?.name ?? n.buyerClubId, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            _stageChip(n.stage),
          ]),
          const SizedBox(height: 5),
          Text('Sprzedający: ${seller?.name ?? n.sellerClubId} • Runda ${n.round}/7', style: const TextStyle(color: FPGTheme.muted, fontSize: 12)),
          const SizedBox(height: 16),
          _dealRow('Kwota transferu', '${n.offeredFee} €', '${n.demandedFee} €'),
          _dealRow('Pensja / tydz.', '${n.offeredWage} €', '${n.demandedWage} €'),
          _dealRow('Bonus podpisowy', '${n.offeredSigningBonus} €', '${n.demandedSigningBonus} €'),
          _dealRow('Długość', '${n.offeredYears} lata', '${n.demandedYears} lata'),
          _dealRow('Rola', '${n.offeredRoleScore}', '${n.demandedRoleScore}'),
          const SizedBox(height: 14),
          if (decision != 'pending') _decisionStatus(decision),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _decision(n, 'reject'), child: const Text('ODRZUĆ'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _decision(n, 'negotiate'), child: const Text('NEGOCJUJ'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: () => _decision(n, 'accept'), child: const Text('AKCEPTUJ'))),
          ]),
        ]),
      ),
    );
  }

  Widget _dealRow(String label, String offer, String demand) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: FPGTheme.muted))),
          Text(offer, style: const TextStyle(color: Colors.white70)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Icon(Icons.arrow_forward, size: 13, color: FPGTheme.muted)),
          Text(demand, style: const TextStyle(fontWeight: FontWeight.w800, color: FPGTheme.accent)),
        ]),
      );

  Widget _decisionStatus(String decision) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity( .05), borderRadius: BorderRadius.circular(10)),
        child: Text(
          decision == 'accepted' ? '✓ ZAWODNIK ZAAKCEPTOWAŁ WARUNKI' : decision == 'negotiating' ? '↔ AGENT NEGOCJUJE' : '✕ OFERTA ODRZUCONA',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      );

  Widget _stageChip(String stage) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: FPGTheme.accent.withOpacity( .12), borderRadius: BorderRadius.circular(8)),
        child: Text(stage.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: FPGTheme.accent, fontSize: 9, fontWeight: FontWeight.w900)),
      );

  Widget _metric(String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity( .04), borderRadius: BorderRadius.circular(11)),
        child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 9, color: FPGTheme.muted))]),
      );

  Widget _empty() => Card(child: Padding(padding: const EdgeInsets.all(26), child: Column(children: const [
    Icon(Icons.mark_email_unread_outlined, size: 42, color: FPGTheme.muted),
    SizedBox(height: 10),
    Text('Brak aktywnych negocjacji', style: TextStyle(fontWeight: FontWeight.w800)),
    SizedBox(height: 6),
    Text('Zainteresowanie klubów pojawi się, gdy Twoja forma, Fame i sytuacja kontraktowa zaczną przyciągać rynek.', textAlign: TextAlign.center, style: TextStyle(color: FPGTheme.muted)),
  ])));
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
