import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/widgets/manage_category_dialog.dart';
import 'package:dnd_cuecard_app/interfaces/categorizable.dart';
import 'package:dnd_cuecard_app/widgets/manage_tag_dialog.dart';
import 'package:dnd_cuecard_app/widgets/tag_management_tab.dart';
import 'package:flutter/material.dart';
import 'package:dnd_cuecard_app/widgets/category_management_tab.dart';
import 'package:provider/provider.dart';

import '../logic/cue_card_creator.dart';
import '../app_state.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';

class ManagementModalView extends StatefulWidget {
  final Function() refreshCardTypes;
  final Function() refreshRarities;
  final Function() refreshTags;

  const ManagementModalView({
    super.key,
    required this.refreshCardTypes,
    required this.refreshRarities,
    required this.refreshTags,
  });

  @override
  State<ManagementModalView> createState() => _ManagementModalViewState();
}

class _ManagementModalViewState extends State<ManagementModalView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Card Types'),
                Tab(text: 'Rarities'),
                Tab(text: 'Tags'),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: TabBarView(
                controller: _tabController,
                children: [
                  CategoryManagementTab<CardType>(
                    categoryLabel: 'Card Type',
                    values: context.watch<AppState>().cardTypes,
                    createFunction: CueCardCreator.createCardType,
                    updateFunction: CueCardCreator.updateCardType,
                    deleteFunction: CueCardCreator.deleteCardType,
                    refreshFunction: widget.refreshCardTypes,
                    showCreateEditDialog: _showCreateEditDialog,
                  ),
                  CategoryManagementTab<Rarity>(
                    categoryLabel: 'Rarity',
                    values: context.watch<AppState>().rarities,
                    createFunction: CueCardCreator.createRarity,
                    updateFunction: CueCardCreator.updateRarity,
                    deleteFunction: CueCardCreator.deleteRarity,
                    refreshFunction: widget.refreshRarities,
                    showCreateEditDialog: _showCreateEditDialog,
                  ),
                  TagManagementTab(
                    categoryLabel: 'Tags',
                    values: context.watch<AppState>().tags,
                    createFunction: CueCardCreator.createTag,
                    updateFunction: CueCardCreator.updateTag,
                    deleteFunction: CueCardCreator.deleteTag,
                    refreshFunction: widget.refreshTags,
                    showCreateEditDialog: _showCreateTagEditDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
  
  void _showCreateEditDialog<T extends Categorizable>({
    required BuildContext context,
    required String label,
    required Future<bool> Function(String, Color) createFunction,
    required Future<bool> Function(int, String, Color) updateFunction,
    required Function(int) deleteFunction,
    required Function() refreshFunction,
    T? item,
  }) {
    showDialog(
      context: context,
      builder: (context) => ManageCategoryDialog<T>(
        item: item,
        label: label,
        createFunction: createFunction,
        updateFunction: updateFunction,
        deleteFunction: deleteFunction,
        refreshFunction: refreshFunction,
      ),
    );
  }

  void _showCreateTagEditDialog({
    required BuildContext context,
    required String label,
    required Future<bool> Function(String) createFunction,
    required Future<bool> Function(int, String) updateFunction,
    required Function(int) deleteFunction,
    required Function() refreshFunction,
    Tag? item,
  }) {
    showDialog(
      context: context,
      builder: (context) => ManageTagDialog(
        item: item,
        label: label,
        createFunction: createFunction,
        updateFunction: updateFunction,
        deleteFunction: deleteFunction,
        refreshFunction: refreshFunction,
      ),
    );
  }
}



