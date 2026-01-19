import 'dart:io';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/cue_card_creator.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RelationshipView extends StatelessWidget {
  const RelationshipView({
    super.key,
    required this.parentA,
    required this.parentB,
    required this.child,
    required this.onParentAChanged,
    required this.onParentBChanged,
    required this.onChildChanged,
    this.onViewCard,
  });

  final CueCard? parentA;
  final CueCard? parentB;
  final CueCard? child;
  final void Function(CueCard?) onParentAChanged;
  final void Function(CueCard?) onParentBChanged;
  final void Function(CueCard?) onChildChanged;
  final void Function(CueCard)? onViewCard;

  bool _isSameCardAlreadyPlaced(CueCard card) {
    return (parentA != null && parentA!.id == card.id) ||
        (parentB != null && parentB!.id == card.id) ||
        (child != null && child!.id == card.id);
  }

  void _tryGetChild(BuildContext context, AppState appState) async {
    if (parentA == null || parentB == null) return;
    final result = await CueCardCreator.getChild(parentA!.id!, parentB!.id!);
    if (result != null) {
      onChildChanged(result);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Query Result'),
          content: const Text('No child found'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  void _tryGetParents(BuildContext context, AppState appState) async {
    if (child == null) return;
    final parents = await CueCardCreator.getParents(child!.id!);
    if (parents.isNotEmpty) {
      onParentAChanged(parents[0]);
      if (parents.length > 1) onParentBChanged(parents[1]);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Query Result'),
          content: const Text('No parents found'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _establishRelationship(BuildContext context, AppState appState) async {
    if (parentA == null || parentB == null || child == null) return;
    final p1 = parentA!.id! < parentB!.id! ? parentA!.id! : parentB!.id!;
    final p2 = parentA!.id! < parentB!.id! ? parentB!.id! : parentA!.id!;
    final error = await CueCardCreator.createRelationship(p1, p2, child!.id!);
    
    if (!context.mounted) return;
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      await appState.loadRelationships();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relationship established')));
    }
  }

  Future<void> _breakRelationship(BuildContext context, AppState appState) async {
    if (parentA == null || parentB == null) return;
    final p1 = parentA!.id! < parentB!.id! ? parentA!.id! : parentB!.id!;
    final p2 = parentA!.id! < parentB!.id! ? parentB!.id! : parentA!.id!;
    await CueCardCreator.deleteRelationship(p1, p2);
    await appState.loadRelationships();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relationship broken')));
  }

  Widget _buildSlot(String label, CueCard? card, void Function(CueCard) onAccept, VoidCallback onClear) {
    return DragTarget<CueCard>(
      onWillAcceptWithDetails: (data) => !_isSameCardAlreadyPlaced(data.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Card(
          child: SizedBox(
            width: 220,
            height: 80,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: card == null
                        ? Center(child: Text(label))
                        : GestureDetector(
                            onTap: () => onViewCard?.call(card),
                            child: Row(
                              children: [
                                if (card.iconFilePath != null)
                                  SizedBox(width: 48, height: 48, child: Image.file(File(card.iconFilePath!), fit: BoxFit.cover)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(card.title ?? 'Untitled')),
                              ],
                            ),
                          ),
                  ),
                ),
                IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSlot('Parent A', parentA, onParentAChanged, () => onParentAChanged(null)),
              const SizedBox(width: 12),
              _buildSlot('Parent B', parentB, onParentBChanged, () => onParentBChanged(null)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSlot('Child', child, onChildChanged, () => onChildChanged(null)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: (parentA != null && parentB != null && child != null)
                    ? () => _establishRelationship(context, appState)
                    : null,
                child: const Text('Establish Relationship'),
              ),
              ElevatedButton(
                onPressed: (parentA != null && parentB != null)
                    ? () => _breakRelationship(context, appState)
                    : null,
                child: const Text('Break Relationship'),
              ),
              ElevatedButton(
                onPressed: (parentA != null && parentB != null) ? () => _tryGetChild(context, appState) : null,
                child: const Text('Try Get Child'),
              ),
              ElevatedButton(
                onPressed: (child != null) ? () => _tryGetParents(context, appState) : null,
                child: const Text('Try Get Parents'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
