/// V19.7 — Interactive relationship scene.
class RelationshipEventChoice {
  final String id;
  final String title;
  final String description;
  final String tone;
  const RelationshipEventChoice({required this.id, required this.title, required this.description, this.tone='neutral'});
}

class RelationshipEvent {
  final String id;
  final String playerId;
  final String target;
  final String title;
  final String description;
  final int createdAbsoluteDay;
  final List<RelationshipEventChoice> choices;
  bool resolved;
  String? chosenId;
  final String? chainId;
  final int stage;


  RelationshipEvent({required this.id, required this.playerId, required this.target, required this.title, required this.description, required this.createdAbsoluteDay, required this.choices, this.resolved=false, this.chosenId, this.chainId, this.stage=1});

  Map<String,dynamic> toJson()=>{'id':id,'playerId':playerId,'target':target,'title':title,'description':description,'createdAbsoluteDay':createdAbsoluteDay,'resolved':resolved,'chosenId':chosenId,'chainId':chainId,'stage':stage,'choices':choices.map((c)=>{'id':c.id,'title':c.title,'description':c.description,'tone':c.tone}).toList()};
  factory RelationshipEvent.fromJson(Map<String,dynamic> j)=>RelationshipEvent(
    id:'${j['id']??''}', playerId:'${j['playerId']??''}', target:'${j['target']??'club'}', title:'${j['title']??''}', description:'${j['description']??''}', createdAbsoluteDay:_i(j['createdAbsoluteDay']), resolved:j['resolved']==true, chosenId:j['chosenId']?.toString(), chainId:j['chainId']?.toString(), stage:_i(j['stage']??1),
    choices:j['choices'] is List ? (j['choices'] as List).whereType<Map>().map((x)=>RelationshipEventChoice(id:'${x['id']??''}',title:'${x['title']??''}',description:'${x['description']??''}',tone:'${x['tone']??'neutral'}')).toList() : const [],
  );
  static int _i(dynamic v)=>v is int?v:int.tryParse('$v')??0;
}
