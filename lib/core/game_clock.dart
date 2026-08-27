class GameClock {
  DateTime currentDate;
  GameClock({DateTime? start}) : currentDate = DateTime(start?.year ?? 2026, start?.month ?? 7, start?.day ?? 24);
  void nextDay() => currentDate = currentDate.add(const Duration(days: 1));
  int get year => currentDate.year;
  int get dayOfYear => currentDate.difference(DateTime(currentDate.year, 1, 1)).inDays + 1;
  bool get isTransferWindowSummer => _isBetween(DateTime(year, 7, 1), DateTime(year, 8, 31));
  bool get isTransferWindowWinter => _isBetween(DateTime(year, 1, 1), DateTime(year, 1, 31));
  bool _isBetween(DateTime from, DateTime to) => !currentDate.isBefore(from) && !currentDate.isAfter(to);
}
