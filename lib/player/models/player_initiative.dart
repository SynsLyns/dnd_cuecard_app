class PlayerInitiativeEncounter {
  const PlayerInitiativeEncounter({required this.combatants});

  final List<PlayerInitiativeCombatant> combatants;

  factory PlayerInitiativeEncounter.fromJson(Map<String, dynamic> json) {
    final value = json['combatants'];
    if (value is! List) {
      throw const FormatException('Invalid shared initiative combatants.');
    }
    return PlayerInitiativeEncounter(
      combatants: value.map((entry) {
        if (entry is! Map) {
          throw const FormatException('Invalid shared initiative combatant.');
        }
        return PlayerInitiativeCombatant.fromJson(
          Map<String, dynamic>.from(entry),
        );
      }).toList(),
    );
  }
}

class PlayerInitiativeCombatant {
  const PlayerInitiativeCombatant({
    required this.name,
    required this.initiative,
    required this.visibility,
    required this.healthStatus,
    required this.isCurrent,
    this.hp,
    this.maxHp,
    this.exhaustion,
    this.concentration,
    this.reactionUsed,
    this.capacity,
    this.cooldown,
    this.cooldownTimers,
  });

  final String name;
  final int initiative;
  final String visibility;
  final String healthStatus;
  final bool isCurrent;
  final int? hp;
  final int? maxHp;
  final int? exhaustion;
  final bool? concentration;
  final bool? reactionUsed;
  final int? capacity;
  final int? cooldown;
  final List<int>? cooldownTimers;

  factory PlayerInitiativeCombatant.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final initiative = json['initiative'];
    final visibility = json['visibility'];
    final healthStatus = json['health_status'];
    final isCurrent = json['is_current'];
    if (name is! String ||
        initiative is! int ||
        visibility is! String ||
        !const {'limited', 'full'}.contains(visibility) ||
        healthStatus is! String ||
        isCurrent is! bool) {
      throw const FormatException('Invalid shared initiative combatant.');
    }

    final timers = json['cooldown_timers'];
    return PlayerInitiativeCombatant(
      name: name,
      initiative: initiative,
      visibility: visibility,
      healthStatus: healthStatus,
      isCurrent: isCurrent,
      hp: json['hp'] is int ? json['hp'] as int : null,
      maxHp: json['max_hp'] is int ? json['max_hp'] as int : null,
      exhaustion: json['exhaustion'] is int ? json['exhaustion'] as int : null,
      concentration: json['concentration'] is bool
          ? json['concentration'] as bool
          : null,
      reactionUsed: json['reaction_used'] is bool
          ? json['reaction_used'] as bool
          : null,
      capacity: json['capacity'] is int ? json['capacity'] as int : null,
      cooldown: json['cooldown'] is int ? json['cooldown'] as int : null,
      cooldownTimers: timers is List ? timers.whereType<int>().toList() : null,
    );
  }
}
