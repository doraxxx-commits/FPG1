class RelationshipAction {
  final String id;
  final String relationship;
  final String title;
  final String description;
  final String icon;
  final int minValue;
  final int cooldownDays;

  const RelationshipAction({
    required this.id,
    required this.relationship,
    required this.title,
    required this.description,
    this.icon = 'hub',
    this.minValue = 0,
    this.cooldownDays = 7,
  });
}

class RelationshipActionResult {
  final String actionId;
  final String title;
  final String description;
  final bool success;

  const RelationshipActionResult({
    required this.actionId,
    required this.title,
    required this.description,
    this.success = true,
  });
}
