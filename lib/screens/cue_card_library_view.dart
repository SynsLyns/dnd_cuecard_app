import 'dart:async';
import 'dart:io';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dnd_cuecard_app/widgets/cue_card/hoverable_cue_card.dart';
import 'campaign_management_dialog.dart';

class CueCardLibraryView extends StatefulWidget {
  const CueCardLibraryView({super.key});

  @override
  State<CueCardLibraryView> createState() => _CueCardLibraryViewState();
}

class _CueCardLibraryViewState extends State<CueCardLibraryView> {
  final List<Tag> _selectedTags = [];
  final Set<int> _selectedCardIds = {};
  int _cueCardsPerPage = 1;
  bool _isSelectingCards = false;
  bool _isSharingSelection = false;

  Timer? _debounce;

  void _onSearchChanged(AppState appState, [String? text, List<Tag>? tags]) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      appState.updateFilteredCueCards(text: text, tags: tags);
    });
  }

  Widget _buildCampaignBar(AppState appState) {
    final activeCampaign = appState.activeCampaign;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                activeCampaign != null ? Icons.campaign : Icons.cloud_outlined,
                size: 20,
                color: activeCampaign != null
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeCampaign != null
                      ? activeCampaign.name
                      : 'No Campaign Selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeCampaign != null) ...[
                IconButton(
                  icon: const Icon(Icons.checklist, size: 18),
                  tooltip: _isSelectingCards
                      ? 'Cancel card selection'
                      : 'Select cards to share',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isSharingSelection
                      ? null
                      : () => setState(() {
                          _isSelectingCards = !_isSelectingCards;
                          _selectedCardIds.clear();
                        }),
                ),
                IconButton(
                  icon: const Icon(Icons.sync, size: 18),
                  tooltip: 'Push all outdated cards to campaign',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isSharingSelection
                      ? null
                      : () => _pushAllOutdated(appState),
                ),
              ],
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: 'Campaigns & Sharing Settings',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CampaignManagementDialog(),
                  );
                },
              ),
            ],
          ),
          if (activeCampaign != null && _isSelectingCards)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedCardIds.length} card(s) selected',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                TextButton.icon(
                  icon: _isSharingSelection
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share, size: 16),
                  label: const Text('Share selected'),
                  onPressed: _selectedCardIds.isEmpty || _isSharingSelection
                      ? null
                      : () => _shareSelectedCards(appState),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pushAllOutdated(AppState appState) async {
    setState(() => _isSharingSelection = true);
    try {
      final result = await appState.pushAllOutdatedCards();
      if (mounted) {
        await _showBatchResult('Push all updates', result);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not push card updates: '
              '${CloudSharingException.userMessage(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingSelection = false);
    }
  }

  Future<void> _shareSelectedCards(AppState appState) async {
    setState(() => _isSharingSelection = true);
    try {
      final cards = await appState.getCardsByIds(_selectedCardIds);
      final result = await appState.shareCards(cards);
      if (mounted) {
        await _showBatchResult('Share selected cards', result);
        setState(() {
          _selectedCardIds.clear();
          _isSelectingCards = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not share selected cards: '
              '${CloudSharingException.userMessage(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingSelection = false);
    }
  }

  Future<void> _showBatchResult(
    String title,
    CardShareBatchResult result,
  ) async {
    if (result.failures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: ${result.succeededCount} card(s) completed.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.succeededCount} succeeded; ${result.failures.length} failed.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: result.failures
                      .map(
                        (failure) => ListTile(
                          dense: true,
                          title: Text(failure.cardTitle),
                          subtitle: Text(failure.message),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    final List<CueCard> filteredCueCards = appState.cueCards;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampaignBar(appState),
          _buildTagList(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildAutocomplete(),
          ),
          Expanded(
            child: filteredCueCards.isEmpty
                ? _buildEmptyState()
                : _buildCardListWithPagination(appState, filteredCueCards),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No matching cue cards found'));
  }

  Widget _buildCardListWithPagination(
    AppState appState,
    List<CueCard> filteredCueCards,
  ) {
    return Column(
      children: [
        Expanded(child: _buildCardList(appState, filteredCueCards)),
        _buildPaginationControls(appState),
      ],
    );
  }

  Widget _buildCardList(AppState appState, List<CueCard> filteredCueCards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        _cueCardsPerPage = (availableHeight / 72.0).floor();
        if (_cueCardsPerPage < 1) _cueCardsPerPage = 1;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.setItemsPerPage(_cueCardsPerPage);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredCueCards.length,
          itemBuilder: (context, index) {
            final cueCard = filteredCueCards[index];
            return _buildCardItem(cueCard, appState);
          },
        );
      },
    );
  }

  Widget _buildCardItem(CueCard cueCard, AppState appState) {
    final selectionMode =
        _isSelectingCards && appState.activeCampaignId != null;
    final cardWidget = HoverableCueCard(
      cueCard: cueCard,
      selectionMode: selectionMode,
      isSelected: cueCard.id != null && _selectedCardIds.contains(cueCard.id),
      onSelectionChanged: cueCard.id == null
          ? null
          : (selected) => setState(() {
              if (selected) {
                _selectedCardIds.add(cueCard.id!);
              } else {
                _selectedCardIds.remove(cueCard.id);
              }
            }),
    );

    if (appState.isRelationshipMode) {
      return Draggable<CueCard>(
        data: cueCard,
        feedback: _buildDraggableFeedback(cueCard),
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  Widget _buildDraggableFeedback(CueCard cueCard) {
    return Material(
      elevation: 6,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Row(
          children: [
            if (cueCard.iconFilePath != null)
              SizedBox(
                width: 40,
                height: 40,
                child: Image.file(
                  File(cueCard.iconFilePath!),
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(child: Text(cueCard.title ?? 'Untitled')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: appState.currentPage > 1
                ? () => appState.goToPage(appState.currentPage - 1)
                : null,
          ),
          Text('Page ${appState.currentPage} of ${appState.totalPages}'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: appState.currentPage < appState.totalPages
                ? () => appState.goToPage(appState.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    AppState appState = context.watch<AppState>();
    return _selectedTags.isEmpty
        ? const SizedBox(height: 32)
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              void removeTag(Tag tag) {
                setState(() {
                  _selectedTags.remove(tag);
                  _onSearchChanged(appState, null, _selectedTags);
                });
              }

              return TagChip(tag: tag.name, onRemove: () => removeTag(tag));
            }).toList(),
          );
  }

  Widget _buildAutocomplete() {
    AppState appState = context.watch<AppState>();
    List<Tag> suggestions = appState.tags;
    late final TextEditingController controller;
    late final FocusNode focusNode;

    void addTag(Tag tag) {
      controller.clear();
      focusNode.unfocus();
      if (_selectedTags.any((t) => t.name == tag.name)) return;
      setState(() {
        _selectedTags.add(tag);
        _onSearchChanged(appState, null, _selectedTags);
      });
    }

    return Autocomplete<Tag>(
      key: ValueKey(suggestions.map((tag) => tag.id).join(',')),
      optionsBuilder: (TextEditingValue textEditingValue) {
        return suggestions.where(
          (option) =>
              !_selectedTags.any((t) => t.name == option.name) &&
              (textEditingValue.text.isEmpty ||
                  option.name.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  )),
        );
      },
      displayStringForOption: (option) => option.name,
      onSelected: addTag,
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
            textEditingController.addListener(() {
              if (appState.searchText != textEditingController.text) {
                _onSearchChanged(appState, textEditingController.text);
              }
            });
            controller = textEditingController;
            focusNode = textFocusNode;
            return TextField(
              controller: textEditingController,
              focusNode: textFocusNode,
              decoration: const InputDecoration(
                labelText: 'Search by tag or title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (String value) {
                final tag = suggestions.firstWhere(
                  (element) =>
                      element.name.toLowerCase() == value.toLowerCase(),
                  orElse: () => Tag(name: ''),
                );
                if (tag.name.isNotEmpty) {
                  addTag(tag);
                }
              },
            );
          },
    );
  }
}
