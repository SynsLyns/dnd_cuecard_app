import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  final url = Platform.environment['SUPABASE_TEST_URL'];
  final anonKey = Platform.environment['SUPABASE_TEST_ANON_KEY'];
  final dmEmail = Platform.environment['SUPABASE_TEST_DM_EMAIL'];
  final dmPassword = Platform.environment['SUPABASE_TEST_DM_PASSWORD'];
  final otherDmEmail = Platform.environment['SUPABASE_TEST_OTHER_DM_EMAIL'];
  final otherDmPassword =
      Platform.environment['SUPABASE_TEST_OTHER_DM_PASSWORD'];
  final missingConfiguration =
      url == null ||
      anonKey == null ||
      dmEmail == null ||
      dmPassword == null ||
      otherDmEmail == null ||
      otherDmPassword == null;

  test(
    'live Supabase RLS permits only campaign owners and members',
    () async {
      final dm = SupabaseClient(url!, anonKey!);
      final otherDm = SupabaseClient(url, anonKey);
      final playerA = SupabaseClient(url, anonKey);
      final playerB = SupabaseClient(url, anonKey);
      final nonMember = SupabaseClient(url, anonKey);

      String? dmCampaignId;
      String? otherCampaignId;
      String? cardId;

      try {
        await dm.auth.signInWithPassword(
          email: dmEmail!,
          password: dmPassword!,
        );
        await otherDm.auth.signInWithPassword(
          email: otherDmEmail!,
          password: otherDmPassword!,
        );

        final dmCampaign = await _createCampaign(dm, 'Live RLS A');
        dmCampaignId = dmCampaign['id'] as String;
        final otherCampaign = await _createCampaign(otherDm, 'Live RLS B');
        otherCampaignId = otherCampaign['id'] as String;

        final cardUuid = const Uuid().v4();
        final insertedCard = await dm
            .from('shared_cards')
            .insert({
              'campaign_id': dmCampaignId,
              'source_card_uuid': cardUuid,
              'payload': {'title': 'Live RLS test card'},
            })
            .select('id')
            .single();
        cardId = insertedCard['id'] as String;

        final otherCard = await otherDm
            .from('shared_cards')
            .insert({
              'campaign_id': otherCampaignId,
              'source_card_uuid': const Uuid().v4(),
              'payload': {'title': 'Private other campaign card'},
            })
            .select('id')
            .single();

        final ownCampaign = await dm
            .from('campaigns')
            .select('id')
            .eq('id', dmCampaignId)
            .maybeSingle();
        expect(ownCampaign, isNotNull);
        final otherDmOwnCampaign = await otherDm
            .from('campaigns')
            .select('id')
            .eq('id', otherCampaignId)
            .maybeSingle();
        expect(otherDmOwnCampaign, isNotNull);

        final foreignCampaign = await dm
            .from('campaigns')
            .select('id')
            .eq('id', otherCampaignId)
            .maybeSingle();
        expect(foreignCampaign, isNull);

        final foreignCardWrite = await dm
            .from('shared_cards')
            .update({
              'payload': {'title': 'unauthorized'},
            })
            .eq('id', otherCard['id'] as String)
            .select('id');
        expect(foreignCardWrite, isEmpty);
        final foreignCampaignDelete = await dm
            .from('campaigns')
            .delete()
            .eq('id', otherCampaignId)
            .select('id');
        expect(foreignCampaignDelete, isEmpty);

        await expectLater(
          dm.from('shared_cards').insert({
            'campaign_id': dmCampaignId,
            'source_card_uuid': const Uuid().v4(),
            'payload': {'oversized': List.filled(100001, 'x').join()},
          }),
          throwsA(isA<PostgrestException>()),
        );

        await playerA.auth.signInAnonymously();
        final joined =
            await playerA.rpc(
                  'join_campaign',
                  params: {
                    'code': dmCampaign['join_code'],
                    'display_name': 'Player A',
                  },
                )
                as List<dynamic>;
        expect(joined, isNotEmpty);
        expect(
          (joined.first as Map<String, dynamic>)['campaign_id'],
          dmCampaignId,
        );

        await playerB.auth.signInAnonymously();
        await playerB.rpc(
          'join_campaign',
          params: {'code': dmCampaign['join_code'], 'display_name': 'Player B'},
        );
        await nonMember.auth.signInAnonymously();

        final memberCards = await playerA
            .from('shared_cards')
            .select('id')
            .eq('campaign_id', dmCampaignId)
            .eq('revoked', false);
        expect(memberCards, hasLength(1));
        final memberCampaign = await playerA
            .from('campaigns')
            .select('id')
            .eq('id', dmCampaignId)
            .maybeSingle();
        expect(memberCampaign, isNotNull);

        final otherCampaignCards = await playerA
            .from('shared_cards')
            .select('id')
            .eq('campaign_id', otherCampaignId);
        expect(otherCampaignCards, isEmpty);

        final otherCampaigns = await playerA
            .from('campaigns')
            .select('id')
            .eq('id', otherCampaignId);
        expect(otherCampaigns, isEmpty);

        final memberList = await playerA
            .from('campaign_members')
            .select('user_id')
            .eq('campaign_id', dmCampaignId);
        expect(memberList, hasLength(2));

        final nonMemberCards = await nonMember
            .from('shared_cards')
            .select('id')
            .eq('campaign_id', dmCampaignId);
        expect(nonMemberCards, isEmpty);
        final nonMemberCampaigns = await nonMember
            .from('campaigns')
            .select('id');
        expect(nonMemberCampaigns, isEmpty);
        final nonMemberMembers = await nonMember
            .from('campaign_members')
            .select('user_id')
            .eq('campaign_id', dmCampaignId);
        expect(nonMemberMembers, isEmpty);
        final nonMemberEvents = await nonMember
            .from('card_share_events')
            .select('id')
            .eq('campaign_id', dmCampaignId);
        expect(nonMemberEvents, isEmpty);

        final memberCampaignUpdate = await playerA
            .from('campaigns')
            .update({'name': 'Player write'})
            .eq('id', dmCampaignId)
            .select('id');
        expect(memberCampaignUpdate, isEmpty);
        final memberCampaignDelete = await playerA
            .from('campaigns')
            .delete()
            .eq('id', dmCampaignId)
            .select('id');
        expect(memberCampaignDelete, isEmpty);
        await expectLater(
          playerA.from('campaigns').insert({
            'dm_id': playerA.auth.currentUser!.id,
            'name': 'Player campaign',
            'join_code': const Uuid().v4().substring(0, 6),
          }),
          throwsA(isA<PostgrestException>()),
        );
        await expectLater(
          playerA.from('campaign_members').insert({
            'campaign_id': dmCampaignId,
            'user_id': playerA.auth.currentUser!.id,
            'display_name': 'Direct join attempt',
          }),
          throwsA(isA<PostgrestException>()),
        );
        final memberDelete = await playerA
            .from('campaign_members')
            .delete()
            .eq('campaign_id', dmCampaignId)
            .eq('user_id', playerB.auth.currentUser!.id)
            .select('user_id');
        expect(memberDelete, isEmpty);

        await expectLater(
          playerA.from('shared_cards').insert({
            'campaign_id': dmCampaignId,
            'source_card_uuid': const Uuid().v4(),
            'payload': {'title': 'Player write'},
          }),
          throwsA(isA<PostgrestException>()),
        );
        final playerUpdate = await playerA
            .from('shared_cards')
            .update({
              'payload': {'title': 'Player write'},
            })
            .eq('id', cardId)
            .select('id');
        expect(playerUpdate, isEmpty);
        final playerDelete = await playerA
            .from('shared_cards')
            .delete()
            .eq('id', cardId)
            .select('id');
        expect(playerDelete, isEmpty);

        await dm
            .from('shared_cards')
            .update({'revoked': true})
            .eq('id', cardId);
        final visibleRevokedCard = await playerA
            .from('shared_cards')
            .select('id')
            .eq('id', cardId);
        expect(visibleRevokedCard, isEmpty);
        final revocationEvent = await playerA
            .from('card_share_events')
            .select('shared_card_id')
            .eq('shared_card_id', cardId);
        expect(revocationEvent, hasLength(1));

        await dm
            .from('campaign_members')
            .delete()
            .eq('campaign_id', dmCampaignId)
            .eq('user_id', playerB.auth.currentUser!.id);
        final removedMemberCards = await playerB
            .from('shared_cards')
            .select('id')
            .eq('campaign_id', dmCampaignId);
        expect(removedMemberCards, isEmpty);

        await dm.from('shared_cards').delete().eq('id', cardId);
        final deletedOwnCard = await dm
            .from('shared_cards')
            .select('id')
            .eq('id', cardId);
        expect(deletedOwnCard, isEmpty);
      } finally {
        if (dmCampaignId != null) {
          await dm.from('campaigns').delete().eq('id', dmCampaignId);
        }
        if (otherCampaignId != null) {
          await otherDm.from('campaigns').delete().eq('id', otherCampaignId);
        }
        await Future.wait([
          dm.dispose(),
          otherDm.dispose(),
          playerA.dispose(),
          playerB.dispose(),
          nonMember.dispose(),
        ]);
      }
    },
    skip: missingConfiguration
        ? 'Set SUPABASE_TEST_URL, SUPABASE_TEST_ANON_KEY, and both DM test accounts to run live RLS checks.'
        : false,
  );
}

Future<Map<String, dynamic>> _createCampaign(
  SupabaseClient client,
  String name,
) async {
  final joinCode = const Uuid().v4().replaceAll('-', '').substring(0, 6);
  return await client
      .from('campaigns')
      .insert({
        'dm_id': client.auth.currentUser!.id,
        'name': name,
        'join_code': joinCode,
      })
      .select()
      .single();
}
