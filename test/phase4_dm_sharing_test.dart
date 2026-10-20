import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/campaign.dart';
import 'package:dnd_cuecard_app/models/card_share.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/tag.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 4: DM App Features Tests', () {
    test('Campaign model serialization works correctly', () {
      final campaign = Campaign(
        id: 'camp-1111-2222',
        dmId: 'dm-user-3333',
        name: 'Curse of Strahd',
        joinCode: 'STRAHD',
        createdAt: DateTime.parse('2026-10-18T20:00:00.000Z'),
      );

      final map = campaign.toMap();
      expect(map['id'], equals('camp-1111-2222'));
      expect(map['dm_id'], equals('dm-user-3333'));
      expect(map['name'], equals('Curse of Strahd'));
      expect(map['join_code'], equals('STRAHD'));
      expect(map['created_at'], equals('2026-10-18T20:00:00.000Z'));

      final reconstructed = Campaign.fromMap(map);
      expect(reconstructed.id, equals(campaign.id));
      expect(reconstructed.name, equals(campaign.name));
      expect(reconstructed.joinCode, equals(campaign.joinCode));
    });

    test(
      'AppState correctly computes CardShareStatus: notShared, upToDate, and changesNotPushed',
      () {
        final appState = AppState();

        final card = CueCard(
          id: 1,
          uuid: 'card-uuid-1234',
          title: 'Shield',
          description: 'An invisible barrier of magical force protects you.',
          notes: 'Cast as a reaction',
          type: 1,
          rarity: 1,
          tags: [Tag(name: 'Abjuration')],
        );

        // 1. Without active campaign -> notShared
        expect(
          appState.getCardShareStatus(card),
          equals(CardShareStatus.notShared),
        );

        // 2. Set active campaign, but card not shared -> notShared
        appState.setActiveCampaign('camp-1111');
        expect(
          appState.getCardShareStatus(card),
          equals(CardShareStatus.notShared),
        );

        // 3. Add share record with current card hash -> upToDate
        final currentHash = card.canonicalHash();
        final share = CardShare(
          cardUuid: card.uuid!,
          campaignId: 'camp-1111',
          sharedCardId: 'cloud-row-555',
          pushedVersion: 1,
          pushedHash: currentHash,
          pushedAt: DateTime.now(),
        );

        appState.cardShares['${card.uuid}_camp-1111'] = share;
        expect(
          appState.getCardShareStatus(card),
          equals(CardShareStatus.upToDate),
        );

        // 4. Modify card locally (e.g. edit description or notes) -> changesNotPushed
        final modifiedCard = card.copyWith(
          description: 'Updated shield description',
        );
        expect(
          appState.getCardShareStatus(modifiedCard),
          equals(CardShareStatus.changesNotPushed),
        );

        // 5. Update share record to new hash -> upToDate again
        final newHash = modifiedCard.canonicalHash();
        appState.cardShares['${card.uuid}_camp-1111'] = share.copyWith(
          pushedVersion: 2,
          pushedHash: newHash,
        );
        expect(
          appState.getCardShareStatus(modifiedCard),
          equals(CardShareStatus.upToDate),
        );

        // 6. Switch campaign -> notShared for different campaign
        appState.setActiveCampaign('camp-other');
        expect(
          appState.getCardShareStatus(modifiedCard),
          equals(CardShareStatus.notShared),
        );
      },
    );

    test(
      'share status can be evaluated for a campaign other than the active one',
      () {
        final appState = AppState()..setActiveCampaign('active-campaign');
        final card = CueCard(
          uuid: 'card-uuid-5678',
          title: 'Healing Word',
          type: 1,
          rarity: 1,
        );
        final otherCampaignShare = CardShare(
          cardUuid: card.uuid!,
          campaignId: 'other-campaign',
          sharedCardId: 'cloud-row-999',
          pushedVersion: 1,
          pushedHash: card.canonicalHash(),
          pushedAt: DateTime.now(),
        );
        appState.cardShares['${card.uuid}_other-campaign'] = otherCampaignShare;

        expect(
          appState.getCardShareStatus(card, campaignId: 'other-campaign'),
          equals(CardShareStatus.upToDate),
        );
        expect(
          appState.getCardShareStatus(card),
          equals(CardShareStatus.notShared),
        );
      },
    );

    test('first share requires at least one selected player', () async {
      final appState = AppState()..setActiveCampaign('camp-1111');
      final card = CueCard(
        uuid: 'card-uuid-first-share',
        title: 'Magic Missile',
        type: 1,
        rarity: 1,
      );

      await expectLater(appState.shareCard(card), throwsA(isA<Exception>()));
      await expectLater(
        appState.shareCard(card, recipientIds: {}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
