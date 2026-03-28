class InitiativeItem {
  String name;
  int initiative;
  int capacity;
  int cooldown;
  int exhaustion;
  int hp;
  int maxHp;
  List<int> cooldownTimers;
  bool toggleState;
  int cd1State;

  InitiativeItem({
    required this.name,
    required this.initiative,
    required this.capacity,
    required this.cooldown,
    this.exhaustion = 0,
    this.hp = 0,
    this.maxHp = 0,
    this.toggleState = false,
    this.cd1State = 0,
  })  : cooldownTimers = List.filled(capacity, 0),
        assert(hp <= maxHp, 'hp cannot exceed maxHp');

  // To copy for state updates
  InitiativeItem copyWith({
    String? name,
    int? initiative,
    int? capacity,
    int? cooldown,
    int? exhaustion,
    int? hp,
    int? maxHp,
    List<int>? cooldownTimers,
    bool? toggleState,
    int? cd1State,
  }) {
    return InitiativeItem(
      name: name ?? this.name,
      initiative: initiative ?? this.initiative,
      capacity: capacity ?? this.capacity,
      cooldown: cooldown ?? this.cooldown,
      exhaustion: exhaustion ?? this.exhaustion,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      toggleState: toggleState ?? this.toggleState,
      cd1State: cd1State ?? this.cd1State,
    )..cooldownTimers = cooldownTimers ?? List.from(this.cooldownTimers);
  }

  void nextTurn() {
    for (int i = 0; i < cooldownTimers.length; i++) {
      if (cooldownTimers[i] > 0) {
        cooldownTimers[i]--;
      }
    }
    if (cd1State > 0) {
      cd1State--;
    }
  }

  void startCooldown(int index) {
    if (index < capacity && cooldownTimers[index] == 0) {
      cooldownTimers[index] = cooldown;
    }
  }

  void toggleToggle() {
    toggleState = !toggleState;
  }

  void startCd1() {
    if (cd1State == 0) {
      cd1State = 1;
    }
  }

  void decrementCd1() {
    if (cd1State > 0) {
      cd1State--;
    }
  }
}
