class InitiativeItem {
  String name;
  int initiative;
  int capacity;
  int cooldown;
  List<int> cooldownTimers;

  InitiativeItem({
    required this.name,
    required this.initiative,
    required this.capacity,
    required this.cooldown,
  }) : cooldownTimers = List.filled(capacity, 0);

  // To copy for state updates
  InitiativeItem copyWith({
    String? name,
    int? initiative,
    int? capacity,
    int? cooldown,
    List<int>? cooldownTimers,
  }) {
    return InitiativeItem(
      name: name ?? this.name,
      initiative: initiative ?? this.initiative,
      capacity: capacity ?? this.capacity,
      cooldown: cooldown ?? this.cooldown,
    )..cooldownTimers = cooldownTimers ?? List.from(this.cooldownTimers);
  }

  void nextTurn() {
    for (int i = 0; i < cooldownTimers.length; i++) {
      if (cooldownTimers[i] > 0) {
        cooldownTimers[i]--;
      }
    }
  }

  void startCooldown(int index) {
    if (index < capacity && cooldownTimers[index] == 0) {
      cooldownTimers[index] = cooldown;
    }
  }
}