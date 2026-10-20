import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NumericRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumericRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = int.tryParse(newValue.text);
    if (parsed == null) return oldValue;
    final clamped = parsed.clamp(min, max);
    if (clamped == parsed) return newValue;
    return TextEditingValue(
      text: clamped.toString(),
      selection: TextSelection.collapsed(offset: clamped.toString().length),
    );
  }
}

class InitiativeTrackerView extends StatefulWidget {
  const InitiativeTrackerView({super.key});

  @override
  State<InitiativeTrackerView> createState() => _InitiativeTrackerViewState();
}

class _InitiativeTrackerViewState extends State<InitiativeTrackerView> {
  final _nameController = TextEditingController();
  final _initiativeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _cooldownController = TextEditingController();
  final _exhaustionController = TextEditingController();
  final _maxHpController = TextEditingController();
  final _hpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _initiativeController.dispose();
    _capacityController.dispose();
    _cooldownController.dispose();
    _exhaustionController.dispose();
    _maxHpController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final initiative = int.tryParse(_initiativeController.text) ?? 0;
    final capacity = int.tryParse(_capacityController.text) ?? 1;
    final cooldown = int.tryParse(_cooldownController.text) ?? 1;
    final exhaustion = int.tryParse(_exhaustionController.text) ?? 0;
    final maxHp = int.tryParse(_maxHpController.text) ?? 0;
    final hp = int.tryParse(_hpController.text) ?? maxHp;

    if (name.isNotEmpty) {
      final item = InitiativeItem(
        name: name,
        initiative: initiative,
        capacity: capacity,
        cooldown: cooldown,
        exhaustion: exhaustion.clamp(0, 6),
        hp: hp.clamp(0, maxHp),
        maxHp: maxHp,
      );
      context.read<InitiativeAppState>().addInitiativeItem(item);
      _nameController.clear();
      _initiativeController.clear();
      _capacityController.clear();
      _cooldownController.clear();
      _exhaustionController.clear();
      _maxHpController.clear();
      _hpController.clear();
      Navigator.of(context).pop();
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Initiative Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _initiativeController,
              decoration: const InputDecoration(labelText: 'Initiative'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cooldownController,
              decoration: const InputDecoration(labelText: 'Cooldown'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _hpController,
              decoration: const InputDecoration(labelText: 'Current HP'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _maxHpController,
              decoration: const InputDecoration(labelText: 'Max HP'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _exhaustionController,
              decoration: const InputDecoration(labelText: 'Exhaustion (0-6)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addItem, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<InitiativeAppState>();
    final items = appState.initiativeItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Initiative Tracker'),
        actions: [
          IconButton(
            tooltip: 'End combat and clear shared encounter',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: appState.campaignId == null && items.isEmpty
                ? null
                : () => _confirmEndCombat(context, appState),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: Column(
        children: [
          if (appState.campaignId == null)
            const ListTile(
              dense: true,
              leading: Icon(Icons.info_outline),
              title: Text(
                'Select a campaign to share initiative with players.',
              ),
            )
          else
            ListTile(
              dense: true,
              leading: appState.syncError != null
                  ? const Icon(Icons.error_outline, color: Colors.red)
                  : appState.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_done_outlined),
              title: Text(
                appState.syncError ??
                    (appState.isSyncing
                        ? 'Sharing initiative with campaign players...'
                        : 'Changes sync to campaign players automatically.'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrentTurn = index == appState.currentTurnIndex;

                return GestureDetector(
                  onTap: () => appState.setCurrentTurn(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isCurrentTurn
                        ? Theme.of(context).colorScheme.surfaceContainerLow
                        : Theme.of(context).colorScheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: isCurrentTurn
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : BorderSide(color: Colors.transparent, width: 0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isCurrentTurn
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    item.initiative.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: isCurrentTurn
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: isCurrentTurn
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isCurrentTurn
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                height: 18,
                                                child: LinearProgressIndicator(
                                                  value: item.maxHp > 0
                                                      ? item.hp / item.maxHp
                                                      : 0,
                                                  minHeight: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHigh,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 180,
                                                height: 28,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        key: ValueKey(
                                                          'hp-${item.name}-${item.maxHp}',
                                                        ),
                                                        initialValue: item.hp
                                                            .toString(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        decoration:
                                                            const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                            ),
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              signed: false,
                                                              decimal: false,
                                                            ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly,
                                                          NumericRangeFormatter(
                                                            min: 0,
                                                            max: item.maxHp,
                                                          ),
                                                        ],
                                                        onChanged: (value) {
                                                          final parsed =
                                                              int.tryParse(
                                                                value,
                                                              );
                                                          if (parsed != null) {
                                                            appState.setHp(
                                                              index,
                                                              parsed,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                          ),
                                                      child: Text(
                                                        '/',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: TextFormField(
                                                        key: ValueKey(
                                                          'maxhp-${item.name}',
                                                        ),
                                                        initialValue: item.maxHp
                                                            .toString(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        decoration:
                                                            const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                            ),
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              signed: false,
                                                              decimal: false,
                                                            ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly,
                                                          NumericRangeFormatter(
                                                            min: 1,
                                                            max: 99999,
                                                          ),
                                                        ],
                                                        onChanged: (value) {
                                                          final parsed =
                                                              int.tryParse(
                                                                value,
                                                              );
                                                          if (parsed != null) {
                                                            appState.setMaxHp(
                                                              index,
                                                              parsed,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Player visibility: ${_visibilityLabel(item.visibility)}',
                                icon: Icon(switch (item.visibility) {
                                  InitiativeVisibility.hidden =>
                                    Icons.visibility_off_outlined,
                                  InitiativeVisibility.limited =>
                                    Icons.visibility_outlined,
                                  InitiativeVisibility.full => Icons.visibility,
                                }),
                                onPressed: () => _showVisibilityMenu(
                                  context,
                                  appState,
                                  index,
                                  item.visibility,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    appState.removeInitiativeItem(index),
                                color: isCurrentTurn
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Exhaustion',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () => appState
                                              .decrementExhaustion(index),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            child: Icon(Icons.remove, size: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.exhaustion.toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => appState
                                              .incrementExhaustion(index),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            child: Icon(Icons.add, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...List.generate(item.capacity, (
                                    chargeIndex,
                                  ) {
                                    final timer =
                                        item.cooldownTimers[chargeIndex];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: timer == 0
                                          ? InkWell(
                                              onTap: () =>
                                                  appState.startCooldown(
                                                    index,
                                                    chargeIndex,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.circle_outlined,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : InkWell(
                                              onTap: () =>
                                                  appState.decrementCooldown(
                                                    index,
                                                    chargeIndex,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    timer.toString(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    );
                                  }),
                                  // Toggle circle
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          appState.toggleToggleState(index),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: item.toggleState
                                              ? Colors.orange
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item.toggleState
                                              ? Icons.circle
                                              : Icons.circle_outlined,
                                          size: 16,
                                          color: item.toggleState
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // CD1 circle (cooldown of 1, no timer display)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: item.cd1State == 0
                                        ? InkWell(
                                            onTap: () =>
                                                appState.startCd1(index),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.circle_outlined,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : InkWell(
                                            onTap: () =>
                                                appState.decrementCd1(index),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Colors.cyan,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  item.cd1State.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: appState.nextTurn,
              child: const Text('Next Turn'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEndCombat(
    BuildContext context,
    InitiativeAppState appState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End combat?'),
        content: const Text(
          'This clears the shared encounter for all campaign players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End combat'),
          ),
        ],
      ),
    );
    if (confirmed == true) await appState.endEncounter();
  }

  void _showVisibilityMenu(
    BuildContext context,
    InitiativeAppState appState,
    int index,
    InitiativeVisibility current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final visibility in InitiativeVisibility.values)
              ListTile(
                leading: Icon(switch (visibility) {
                  InitiativeVisibility.hidden => Icons.visibility_off,
                  InitiativeVisibility.limited => Icons.visibility_outlined,
                  InitiativeVisibility.full => Icons.visibility,
                }),
                title: Text(_visibilityLabel(visibility)),
                subtitle: Text(_visibilityDescription(visibility)),
                trailing: current == visibility
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  appState.setVisibility(index, visibility);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _visibilityLabel(InitiativeVisibility visibility) =>
      switch (visibility) {
        InitiativeVisibility.hidden => 'Hidden',
        InitiativeVisibility.limited => 'Limited',
        InitiativeVisibility.full => 'Full',
      };

  String _visibilityDescription(InitiativeVisibility visibility) =>
      switch (visibility) {
        InitiativeVisibility.hidden => 'Not shown to players.',
        InitiativeVisibility.limited =>
          'Name, initiative, and a health status label.',
        InitiativeVisibility.full =>
          'Exact HP, exhaustion, concentration, reaction, and cooldowns.',
      };
}
