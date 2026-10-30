import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/contrast.dart';
import '../models/player_shared_card.dart';

class PlayerSharedCardTile extends StatefulWidget {
  const PlayerSharedCardTile({
    super.key,
    required this.card,
    required this.hasUpdated,
    required this.onExpanded,
  });

  final PlayerSharedCard card;
  final bool hasUpdated;
  final VoidCallback onExpanded;

  @override
  State<PlayerSharedCardTile> createState() => _PlayerSharedCardTileState();
}

class _PlayerSharedCardTileState extends State<PlayerSharedCardTile> {
  bool _isExpanded = false;

  PlayerSharedCard get card => widget.card;
  Color get _typeColor => _colorFromArgb(card.typeColor, AppColors.matcha);
  Color get _rarityColor => _colorFromArgb(card.rarityColor, AppColors.ground);

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) widget.onExpanded();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            child: _isExpanded
                ? _buildExpandedHeading()
                : _buildCollapsedHeading(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (card.schemaVersion > 1)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'This card uses a newer format. Some details may not be shown.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      RepaintBoundary(child: _buildCardFace()),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeading() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildIcon(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                _buildMetadata(),
              ],
            ),
          ),
          if (widget.hasUpdated) ...[
            const SizedBox(width: 8),
            _metadataChip(
              'Updated',
              background: AppColors.matcha,
              inverse: true,
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, color: AppColors.matcha),
        ],
      ),
    );
  }

  Widget _buildExpandedHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(child: _buildMetadata()),
          if (widget.hasUpdated) ...[
            const SizedBox(width: 8),
            _metadataChip(
              'Updated',
              background: AppColors.matcha,
              inverse: true,
            ),
          ],
          IconButton(
            tooltip: 'Collapse card',
            onPressed: _toggleExpanded,
            icon: const Icon(Icons.expand_less, color: AppColors.matcha),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (card.typeName != null)
          _metadataChip(card.typeName!, background: _typeColor, inverse: true),
        if (card.rarityName != null)
          _metadataChip(
            card.rarityName!,
            background: AppColors.panel,
            borderColor: AppColors.border,
          ),
        for (final tag in card.tags)
          _metadataChip(tag, background: AppColors.sage),
      ],
    );
  }

  Widget _metadataChip(
    String label, {
    required Color background,
    Color? borderColor,
    bool inverse = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: inverse ? readableOn(background) : AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardFace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardHeight = (width / 1.78).clamp(360.0, double.infinity);
        final bannerHeight = (width * 0.16).clamp(56.0, 88.0);
        return SizedBox(
          height: cardHeight,
          child: Column(
            children: [
              SizedBox(height: bannerHeight, child: _buildBanner()),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.paper,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      card.description ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 23,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              _buildFooter(width),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    final titleStyle = Theme.of(context)
        .extension<AppTypography>()!
        .bonaNovaSC
        .copyWith(fontSize: 28, color: readableOn(_rarityColor));

    return Container(
      color: _typeColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildIcon(size: 52, backgroundColor: _typeColor),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              decoration: ShapeDecoration(
                color: _rarityColor,
                shape: OvalBorder(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: _rarityColor,
                    shape: OvalBorder(
                      side: BorderSide(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(card.title, maxLines: 1, style: titleStyle),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Tooltip(
              message: 'Requirements',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.requirements ?? '',
                  maxLines: 1,
                  style: Theme.of(context)
                      .extension<AppTypography>()!
                      .bonaNovaSC
                      .copyWith(fontSize: 30, color: readableOn(_typeColor)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double width) {
    final firstValue = card.box1;
    final secondValue = card.box2;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: width < 500 ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.footer,
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              card.notes ?? '',
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (firstValue != null || secondValue != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (firstValue != null) _valueChip(firstValue),
                if (firstValue != null && secondValue != null)
                  const SizedBox(height: 6),
                if (secondValue != null) _valueChip(secondValue),
              ],
            ),
        ],
      ),
    );
  }

  Widget _valueChip(String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 58, maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.matcha,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIcon({required double size, Color? backgroundColor}) {
    final ringColor = readableOn(backgroundColor ?? AppColors.sage);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: ringColor, width: 2),
        borderRadius: BorderRadius.circular(size * 0.25),
        color: backgroundColor ?? AppColors.sage,
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        key: ValueKey('shared-card-icon-clip-$size'),
        borderRadius: BorderRadius.circular(size * 0.25 - 2),
        child: card.iconBytes == null
            ? ColoredBox(
                color: backgroundColor ?? AppColors.sage,
                child: Icon(
                  Icons.water_drop_outlined,
                  size: size * 0.48,
                  color: ringColor,
                ),
              )
            : Image.memory(card.iconBytes!, fit: BoxFit.cover),
      ),
    );
  }

  Color _colorFromArgb(int? value, Color fallback) {
    if (value == null) return fallback;
    return Color(value & 0xFFFFFFFF);
  }
}
