import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _initiativeController.dispose();
    _capacityController.dispose();
    _cooldownController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final initiative = int.tryParse(_initiativeController.text) ?? 0;
    final capacity = int.tryParse(_capacityController.text) ?? 1;
    final cooldown = int.tryParse(_cooldownController.text) ?? 1;

    if (name.isNotEmpty) {
      final item = InitiativeItem(
        name: name,
        initiative: initiative,
        capacity: capacity,
        cooldown: cooldown,
      );
      context.read<InitiativeAppState>().addInitiativeItem(item);
      _nameController.clear();
      _initiativeController.clear();
      _capacityController.clear();
      _cooldownController.clear();
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addItem,
            child: const Text('Add'),
          ),
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
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrentTurn = index == appState.currentTurnIndex;
                return GestureDetector(
                  onTap: () => appState.setCurrentTurn(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isCurrentTurn 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith( 
                              fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentTurn ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Init: ${item.initiative}',
                            textAlign: TextAlign.center,
                            style: isCurrentTurn ? TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ) : null,
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              item.capacity,
                              (chargeIndex) {
                                final timer = item.cooldownTimers[chargeIndex];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: timer == 0
                                      ? IconButton(
                                          icon: const Icon(Icons.circle, color: Colors.grey),
                                          onPressed: () => appState.startCooldown(index, chargeIndex),
                                        )
                                      : InkWell(
                                          onTap: () => appState.decrementCooldown(index, chargeIndex),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                timer.toString(),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => appState.removeInitiativeItem(index),
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
}