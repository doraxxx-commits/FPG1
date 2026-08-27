import 'dart:math';
import '../models/player.dart';
import '../models/club.dart';

class NewsItem {
  final String id;
  final String authorName;
  final String authorHandle;
  final String avatarType; // 'troll', 'fan', 'insider', 'stat', 'journal'
  final String content;
  final DateTime date;
  final int likes;
  final int retweets;
  final bool isHate;

  NewsItem({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.avatarType,
    required this.content,
    required this.date,
    required this.likes,
    required this.retweets,
    this.isHate = false,
  });
}

class NewsEngine {
  static final Random _rnd = Random();

  // 1. GENERATOR IMION I HANDLE KONT (Nieskończona liczba kont)
  static const List<String> _firstNames = ['Krystian', 'Marek', 'Bartek', 'Piotr', 'Kamil', 'Kuba', 'Janek', 'Sebix', 'Artur', 'Tomek'];
  static const List<String> _nickPrefixes = ['Futbolowy', 'Anty', 'Ultra', 'Tactics', 'Prawdziwy', 'Młody', 'Szybki', 'Stadionowy'];
  static const List<String> _nickSuffixes = ['Maniak', 'Znawca', 'Kibol', 'Scout', 'Ekspert', 'Analityk', 'Fanatyk', 'Głos'];

  // 2. WIDGETY / BAZY SŁÓW DLA KOMBINATORYKI PROCEDURALNEJ

  // EMOJI & HASHTAGI
  static const List<String> _emojisTroll = ['🤡', '💀', '📉', '😭', '🗑️', '🤮', '😴', '❌'];
  static const List<String> _emojisHype = ['🔥', '⚡', '🐐', '👑', '💣', '🚀', '⭐', '🎯'];
  static const List<String> _emojisMedia = ['🚨', '📊', '💬', '👀', '📌', '📰', '✈️', '💰'];

  // SLANG TROLLI I HEJTERÓW (PRZEDROSTKI)
  static const List<String> _trollIntros = [
    'XDDDD', 'Ja nie wierzę...', 'Błagam was,', 'Co to ma być?!', 'Kolejny mecz i',
    'Niezły flop...', 'Czy tylko ja widzę, że', 'Dramat.', 'HIT SEZONU:',
    'Mam dość.', 'Oddajcie mi czas za ten mecz,', 'Kto mu dał profesjonalny kontrakt?!'
  ];

  // OPISY SŁABOŚCI / PRZEZWISKA
  static const List<String> _trollNicknames = [
    'ten ogór', 'ten parodysta', 'to drewno', 'ten chłop z przypadku',
    'król ławki rezerwowych', 'alibi-piłkarz', 'turysta na boisku'
  ];

  // CZYNNOŚCI TROLLI
  static const List<String> _trollActions = [
    'nadaje się co najwyżej do 4. ligi.',
    'potyka się o własne nogi przy każdym przyjęciu.',
    'ma zwrotność jak czołg z II Wojny Światowej.',
    'znowu gra na alibi i podaje tylko do tyłu.',
    'sprawia, że gramy w dziesięciu na jedenastu.',
    'zaraz dostanie bilet w jedną stronę na trybuny.',
    'zarabia tysiące za potknięcia w polu karnym.'
  ];

  // SLANG HYPU I FANÓW (PRZEDROSTKI)
  static const List<String> _fanIntros = [
    'Nie mam słów! 🔥', 'Wielki szacunek.', 'Panowie i Panie,', 'Mówcie co chcecie, ale',
    'Prawdziwy majstersztyk!', 'Widzieliście to?!', 'Czapki z głów,', 'CO ZA GOŚĆ!'
  ];

  // OPISY ZALET / POCHWAŁY
  static const List<String> _fanPraise = [
    'to po prostu czysta poezja futbolu.',
    'zamiata całą ligę bez popijania.',
    'ma wizję gry jak wybitny rozgrywający.',
    'prowadzi piłkę przy nodze jak na sznurku.',
    'rozwija się w zastraszającym tempie!',
    'to przyszły reprezentant kraju, zobaczycie.'
  ];

  // BAZA DZIENNIKARSKA / MEDIA (NAGŁÓWKI INFORMACYJNE)
  static const List<String> _mediaIntros = [
    'INFORMACJE KULISOWE:', 'WEDŁUG NASZYCH ŹRÓDEŁ:', 'RAPORT SKAUTINGOWY:',
    'RYNEK TRANSFEROWY:', 'ANALIZA POCIĄGOWA:'
  ];

  static const List<String> _mediaActions = [
    'znajduje się pod stałą obserwacją analityków z zagranicy.',
    'budzi ogromne emocje wśród władz klubu.',
    'generuje spore zainteresowanie na rynku transferowym.',
    'może wkrótce otrzymać propozycję przedłużenia umowy.'
  ];

  // 3. GENERATOR LOSOWEJ TOŻSAMOŚCI KONT
  static Map<String, String> _generateRandomAccount() {
    final typeRnd = _rnd.nextDouble();
    String type = 'fan';
    if (typeRnd < 0.35) type = 'troll';
    else if (typeRnd < 0.65) type = 'fan';
    else if (typeRnd < 0.85) type = 'insider';
    else type = 'stat';

    final pName = _nickPrefixes[_rnd.nextInt(_nickPrefixes.length)];
    final sName = _nickSuffixes[_rnd.nextInt(_nickSuffixes.length)];
    final fName = _firstNames[_rnd.nextInt(_firstNames.length)];

    final handle = '@${pName.toLowerCase()}_${sName.toLowerCase()}${_rnd.nextInt(99)}';
    final name = type == 'troll' ? '$pName $sName' : '$fName | $sName';

    return {
      'name': name,
      'handle': handle,
      'type': type,
    };
  }

  // 4. GŁÓWNA KOMBINAJCA PROCEDURALNA ZDAŃ
  static String _buildProceduralTweet(Player player, Club club, String type) {
    final name = player.name;
    final clubName = club.name;
    final ovr = player.overall;

    // A) PROCEDURALNY HEJT / TROLLING (Kombinacje z 4 baz)
    if (type == 'troll' || (ovr < 65 && _rnd.nextBool())) {
      final emoji = _emojisTroll[_rnd.nextInt(_emojisTroll.length)];
      final intro = _trollIntros[_rnd.nextInt(_trollIntros.length)];
      final nick = _trollNicknames[_rnd.nextInt(_trollNicknames.length)];
      final action = _trollActions[_rnd.nextInt(_trollActions.length)];

      final templates = [
        '$emoji $intro $name w $clubName $action',
        '$intro $name ($nick) $action $emoji',
        '$emoji $name ma OVR $ovr i $action $intro',
        '$intro Patrzenie jak $name gra w $clubName to czysta katusza... $emoji'
      ];

      return templates[_rnd.nextInt(templates.length)];
    }

    // B) PROCEDURALNY HYP / PSYCHO-FANI
    if (type == 'fan') {
      final emoji = _emojisHype[_rnd.nextInt(_emojisHype.length)];
      final intro = _fanIntros[_rnd.nextInt(_fanIntros.length)];
      final praise = _fanPraise[_rnd.nextInt(_fanPraise.length)];

      final templates = [
        '$emoji $intro $name w barwach $clubName $praise',
        '$intro $name z OVR $ovr $praise $emoji #Futbol',
        '$emoji Dajcie dla $name więcej minut! To co robi na boisku $praise'
      ];

      return templates[_rnd.nextInt(templates.length)];
    }

    // C) PROCEDURALNY MEDIA / INSIDER / TRANSFERY
    final emoji = _emojisMedia[_rnd.nextInt(_emojisMedia.length)];
    final intro = _mediaIntros[_rnd.nextInt(_mediaIntros.length)];
    final action = _mediaActions[_rnd.nextInt(_mediaActions.length)];
    final fee = (player.value > 0 ? player.value : 250000) + (_rnd.nextInt(40) * 10000);

    final templates = [
      '$emoji $intro $name (lat ${player.age}, OVR $ovr) $action #Transfery',
      '$emoji $clubName: Sytuacja wokół $name robi się gorąca. Wartość rynkowa to około ${fee} €!',
      '$intro $name przykuwa uwagę skautów. Czy $clubName zdoła go zatrzymać na kolejny sezon?'
    ];

    return templates[_rnd.nextInt(templates.length)];
  }

  // 5. GENEROWANIE PEŁNEGO FEEDU DLA DNIA
  static List<NewsItem> generateFeed({
    required Player player,
    required Club playerClub,
    required DateTime currentDate,
    int count = 25, // Aż 25 dynamicznych postów w feedzie
  }) {
    final List<NewsItem> list = [];

    for (int i = 0; i < count; i++) {
      final acc = _generateRandomAccount();
      final type = acc['type']!;
      final content = _buildProceduralTweet(player, playerClub, type);
      final isHate = type == 'troll';

      final likes = isHate ? _rnd.nextInt(400) + 5 : _rnd.nextInt(2500) + 40;
      final rts = (likes * (_rnd.nextDouble() * 0.35)).round();

      list.add(NewsItem(
        id: '${currentDate.millisecondsSinceEpoch}_${_rnd.nextInt(99999)}',
        authorName: acc['name']!,
        authorHandle: acc['handle']!,
        avatarType: type,
        content: content,
        date: currentDate.subtract(Duration(minutes: i * 11 + _rnd.nextInt(8))),
        likes: likes,
        retweets: rts,
        isHate: isHate,
      ));
    }

    return list;
  }
}
