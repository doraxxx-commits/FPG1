/// V19.3 — Contextual choice available in an active career storyline.
class CareerStorylineChoice {
  final String id;
  final String title;
  final String description;
  final String tone;
  const CareerStorylineChoice({required this.id, required this.title, required this.description, this.tone = 'neutral'});
}
