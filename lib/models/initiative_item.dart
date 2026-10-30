enum InitiativeVisibility { hidden, limited, full }

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
  InitiativeVisibility visibility;

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
    this.visibility = InitiativeVisibility.limited,
  }) : cooldownTimers = List.filled(capacity, 0),
       assert(hp <= maxHp, 'hp cannot exceed maxHp');

  factory InitiativeItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final initiative = json['initiative'];
    final capacity = json['capacity'];
    final cooldown = json['cooldown'];
    final exhaustion = json['exhaustion'];
    final hp = json['hp'];
    final maxHp = json['max_hp'];
    final cooldownTimers = json['cooldown_timers'];
    final toggleState = json['toggle_state'];
    final cd1State = json['cd1_state'];
    final visibility = json['visibility'];

    if (name is! String ||
        initiative is! int ||
        capacity is! int ||
        capacity < 0 ||
        cooldown is! int ||
        exhaustion is! int ||
        hp is! int ||
        maxHp is! int ||
        cooldownTimers is! List ||
        cooldownTimers.length != capacity ||
        cooldownTimers.any((timer) => timer is! int) ||
        toggleState is! bool ||
        cd1State is! int ||
        visibility is! String) {
      throw const FormatException('Invalid saved initiative item.');
    }

    final InitiativeVisibility parsedVisibility;
    try {
      parsedVisibility = InitiativeVisibility.values.byName(visibility);
    } on ArgumentError {
      throw const FormatException('Invalid saved initiative visibility.');
    }

    return InitiativeItem(
      name: name,
      initiative: initiative,
      capacity: capacity,
      cooldown: cooldown,
      exhaustion: exhaustion,
      hp: hp,
      maxHp: maxHp,
      toggleState: toggleState,
      cd1State: cd1State,
      visibility: parsedVisibility,
    )..cooldownTimers = cooldownTimers.cast<int>();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'initiative': initiative,
    'capacity': capacity,
    'cooldown': cooldown,
    'exhaustion': exhaustion,
    'hp': hp,
    'max_hp': maxHp,
    'cooldown_timers': cooldownTimers,
    'toggle_state': toggleState,
    'cd1_state': cd1State,
    'visibility': visibility.name,
  };

  String get healthStatus {
    if (hp <= 0) return 'Down';
    if (maxHp <= 0 || hp * 4 <= maxHp) return 'Near Death';
    if (hp * 2 <= maxHp) return 'Bloodied';
    return 'Healthy';
  }

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
    InitiativeVisibility? visibility,
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
      visibility: visibility ?? this.visibility,
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
