import 'package:dnd_cuecard_app/interfaces/colorable.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:dnd_cuecard_app/widgets/manage_item_dialog.dart';
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

    void showCreateEditDialog<T extends Nameable>({
      required String label,
      required Future<bool> Function(String name, Color? color) onCreate,
      required Future<bool> Function(int id, String name, Color? color) onUpdate,
      required Function(int) onDelete,
      required Function() onRefresh,
      T? item,
      bool supportsColor = false,
    }) {
      showDialog(
        context: context,
        builder: (context) => ManageItemDialog(
          id: item?.id,
          initialName: item?.name,
          initialColor: item is Colorable ? (item as Colorable).color : null,
          supportsColor: supportsColor,
          label: label,
          onCreate: onCreate,
          onUpdate: onUpdate,
          onDelete: onDelete,
          onRefresh: onRefresh,
        ),
      );
    }

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
                    onCreate: (String name, Color? color) => CueCardCreator.createCardType(name, color!),
                    onUpdate: (int id, String name, Color? color) => CueCardCreator.updateCardType(id, name, color ?? Colors.white),
                    onDelete: CueCardCreator.deleteCardType,
                    onRefresh: widget.refreshCardTypes,
                    showCreateEditDialog: showCreateEditDialog,
                  ),
                  CategoryManagementTab<Rarity>(
                    categoryLabel: 'Rarity',
                    values: context.watch<AppState>().rarities,
                    onCreate: (String name, Color? color) => CueCardCreator.createRarity(name, color!),
                    onUpdate: (int id, String name, Color? color) => CueCardCreator.updateRarity(id, name, color ?? Colors.white),
                    onDelete: CueCardCreator.deleteRarity,
                    onRefresh: widget.refreshRarities,
                    showCreateEditDialog: showCreateEditDialog,
                  ),
                  CategoryManagementTab<Tag>(
                    categoryLabel: 'Tags',
                    values: context.watch<AppState>().tags,
                    onCreate: (String name, Color? color) => CueCardCreator.createTag(name),
                    onUpdate: (int id, String name, Color? color) => CueCardCreator.updateTag(id, name),
                    onDelete: CueCardCreator.deleteTag,
                    onRefresh: widget.refreshTags,
                    showCreateEditDialog: showCreateEditDialog,
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
}



