import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/player_initiative.dart';

class PlayerInitiativePanel extends StatelessWidget {
  const PlayerInitiativePanel({
    super.key,
    required this.encounter,
    required this.compact,
  });

  final PlayerInitiativeEncounter? encounter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final combatants = encounter?.combatants ?? const [];
    return Container(
      color: compact ? AppColors.ground : AppColors.sidebar,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Initiative',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Fraunces',
                fontSize: compact ? 22 : 18,
              ),
            ),
            const SizedBox(height: 10),
            if (combatants.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(
                  'No active initiative encounter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final combatant in combatants)
                _PlayerCombatantCard(combatant: combatant),
          ],
        ),
      ),
    );
  }
}

class _PlayerCombatantCard extends StatelessWidget {
  const _PlayerCombatantCard({required this.combatant});

  final PlayerInitiativeCombatant combatant;

  @override
  Widget build(BuildContext context) {
    final hasExactHp =
        combatant.visibility == 'full' &&
        combatant.hp != null &&
        combatant.maxHp != null;

    return Container(
      key: ValueKey('initiative-card-${combatant.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: combatant.isCurrent
            ? AppColors.sage.withValues(alpha: 0.45)
            : AppColors.paper,
        border: Border.all(
          color: combatant.isCurrent ? AppColors.matcha : AppColors.rule,
          width: combatant.isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: combatant.isCurrent ? AppColors.matcha : AppColors.sage,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              combatant.initiative.toString(),
              style: TextStyle(
                color: combatant.isCurrent
                    ? AppColors.ground
                    : AppColors.matcha,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      combatant.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: combatant.isCurrent
                            ? AppColors.matcha
                            : AppColors.ink,
                      ),
                    ),
                    if (combatant.isCurrent)
                      _StatusPill(
                        label: 'Current turn',
                        color: AppColors.matcha,
                        foreground: AppColors.ground,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasExactHp)
                  _HealthBar(combatant: combatant)
                else
                  _StatusPill(
                    label: combatant.healthStatus,
                    color: AppColors.sage,
                    foreground: AppColors.matcha,
                  ),
                if (combatant.visibility == 'full') ...[
                  const SizedBox(height: 8),
                  _CombatantDetails(combatant: combatant),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.combatant});

  final PlayerInitiativeCombatant combatant;

  @override
  Widget build(BuildContext context) {
    final hp = combatant.hp!;
    final maxHp = combatant.maxHp!;
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxHp > 0 ? (hp / maxHp).clamp(0, 1).toDouble() : 0,
              minHeight: 24,
              color: AppColors.rule,
              backgroundColor: AppColors.sage,
            ),
          ),
          Text(
            '$hp / $maxHp HP',
            style: const TextStyle(
              color: AppColors.matcha,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CombatantDetails extends StatelessWidget {
  const _CombatantDetails({required this.combatant});

  final PlayerInitiativeCombatant combatant;

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[
      if (combatant.exhaustion != null)
        Text(
          'Exhaustion  ${combatant.exhaustion}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      if (combatant.cooldown != null)
        Text(
          'Cooldown ${combatant.cooldown} turns',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (combatant.cooldownTimers != null)
        for (var index = 0; index < combatant.cooldownTimers!.length; index++)
          _Indicator(
            label:
                'Cooldown charge ${index + 1}: '
                '${combatant.cooldownTimers![index]} turns remaining',
            value: combatant.cooldownTimers![index],
            activeColor: AppColors.matcha,
          ),
      if (combatant.concentration != null)
        _Indicator(
          label: combatant.concentration!
              ? 'Concentrating'
              : 'Not concentrating',
          active: combatant.concentration!,
          activeColor: Colors.orange,
        ),
      if (combatant.reactionUsed != null)
        _Indicator(
          label: combatant.reactionUsed! ? 'Reaction used' : 'Reaction ready',
          active: combatant.reactionUsed!,
          activeColor: Colors.cyan,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: details,
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.label,
    required this.activeColor,
    this.active = false,
    this.value,
  });

  final String label;
  final Color activeColor;
  final bool active;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final isActive = value != null ? value! > 0 : active;
    return Semantics(
      label: label,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: value != null && isActive
            ? Text(
                value.toString(),
                style: const TextStyle(
                  color: AppColors.ground,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                active ? Icons.circle : Icons.circle_outlined,
                size: 16,
                color: isActive ? AppColors.ground : Colors.grey,
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
