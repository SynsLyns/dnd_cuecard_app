-- Run after the sharing schema in a disposable Supabase project or test DB.
-- The transaction rolls back all fixtures. Distinct JWT subjects exercise RLS.
begin;

do $$
declare
  test_users uuid[] := array[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid
  ];
begin
  insert into auth.users (id, email)
  select user_id, user_id::text || '@sharing-test.invalid'
  from unnest(test_users) as user_id
  on conflict (id) do nothing;
  update auth.users
  set is_anonymous = true
  where id = '66666666-6666-6666-6666-666666666666';
end;
$$;

set local role authenticated;

-- DM A owns Campaign A.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
insert into public.campaigns (id, dm_id, name, join_code)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'Campaign A',
  'CAMP01'
);

insert into public.shared_cards (id, campaign_id, source_card_uuid, payload)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '99999999-9999-9999-9999-999999999999',
  '{"title": "Fireball"}'::jsonb
);
insert into public.initiative_encounters (campaign_id, player_state)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '{"schema_version": 1, "combatants": [{"name": "Guard", "initiative": 12, "visibility": "limited", "health_status": "Healthy", "is_current": true}]}'::jsonb
);

-- Anonymous Auth users cannot see active campaign data or join.
set local "request.jwt.claim.sub" to '66666666-6666-6666-6666-666666666666';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.campaigns;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: anonymous user saw a campaign';
  end if;
  select count(*) into visible_count from public.initiative_encounters
  where active;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: anonymous user saw initiative';
  end if;
  begin
    perform * from public.join_campaign('CAMP01', 'Anonymous');
    raise exception 'TEST FAILED: anonymous user joined a campaign';
  exception when raise_exception then
    if sqlerrm not like '%registered account%' then
      raise;
    end if;
  end;
end;
$$;

-- DM B owns Campaign B and its card.
set local "request.jwt.claim.sub" to '55555555-5555-5555-5555-555555555555';
insert into public.campaigns (id, dm_id, name, join_code)
values (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '55555555-5555-5555-5555-555555555555',
  'Campaign B',
  'CAMP02'
);
insert into public.shared_cards (id, campaign_id, source_card_uuid, payload)
values (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '88888888-8888-8888-8888-888888888888',
  '{"title": "Secret"}'::jsonb
);

-- DM A can manage only its own campaigns and cards.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
do $$
declare
  changed_rows integer;
begin
  update public.campaigns set name = 'Campaign A Updated'
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 1 then
    raise exception 'TEST FAILED: DM could not update its campaign';
  end if;

  select count(*) into changed_rows from public.campaigns
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: DM saw another DM campaign';
  end if;

  update public.shared_cards set payload = '{"title":"Updated"}'::jsonb
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 1 then
    raise exception 'TEST FAILED: DM could not update its shared card';
  end if;

  begin
    insert into public.shared_cards (campaign_id, source_card_uuid, payload)
    values (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      gen_random_uuid(),
      '{"title":"Unauthorized"}'::jsonb
    );
    raise exception 'TEST FAILED: DM wrote to another DM campaign';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

-- Members can join only through the RPC, see campaign peers, and read cards
-- only in their own campaign.
set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
select * from public.join_campaign('CAMP01', 'Player Alpha');

set local "request.jwt.claim.sub" to '33333333-3333-3333-3333-333333333333';
select * from public.join_campaign('CAMP01', 'Player Beta');

-- Newly shared cards stay hidden until the DM explicitly chooses recipients.
set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.shared_cards
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if visible_count <> 0 then
    raise exception 'TEST FAILED: card was visible before DM granted access';
  end if;
end;
$$;

set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
insert into public.shared_card_recipients (
  campaign_id, shared_card_id, user_id
)
values
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '22222222-2222-2222-2222-222222222222'
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '33333333-3333-3333-3333-333333333333'
  );

set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
do $$
declare
  visible_count integer;
  changed_rows integer;
begin
  select count(*) into visible_count from public.shared_cards
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if visible_count <> 1 then
    raise exception 'TEST FAILED: campaign member did not see its card';
  end if;

  select count(*) into visible_count from public.campaigns
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if visible_count <> 0 then
    raise exception 'TEST FAILED: member saw a different campaign';
  end if;

  select count(*) into visible_count from public.shared_cards
  where campaign_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if visible_count <> 0 then
    raise exception 'TEST FAILED: member saw a different campaign card';
  end if;

  select count(*) into visible_count from public.campaign_members
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if visible_count <> 2 then
    raise exception 'TEST FAILED: members could not see campaign peers';
  end if;

  select count(*) into visible_count from public.initiative_encounters
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if visible_count <> 1 then
    raise exception 'TEST FAILED: campaign member could not see initiative';
  end if;

  update public.campaigns set name = 'Player write'
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: member updated campaign details';
  end if;

  delete from public.campaigns
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: member deleted a campaign';
  end if;

  delete from public.campaign_members
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    and user_id = '33333333-3333-3333-3333-333333333333';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: member removed another campaign member';
  end if;

  begin
    insert into public.campaign_members (campaign_id, user_id, display_name)
    values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '44444444-4444-4444-4444-444444444444',
      'Direct join attempt'
    );
    raise exception 'TEST FAILED: player inserted a campaign member directly';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.shared_cards (campaign_id, source_card_uuid, payload)
    values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      gen_random_uuid(),
      '{"title":"Player write"}'::jsonb
    );
    raise exception 'TEST FAILED: player inserted a shared card';
  exception when insufficient_privilege then
    null;
  end;

  update public.shared_cards set payload = '{"title":"Player write"}'::jsonb
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: player updated a shared card';
  end if;

  delete from public.shared_cards
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: player deleted a shared card';
  end if;

  update public.initiative_encounters
  set player_state = '{"combatants":[]}'::jsonb
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  get diagnostics changed_rows = row_count;
  if changed_rows <> 0 then
    raise exception 'TEST FAILED: player updated initiative';
  end if;
end;
$$;

-- The DM can hide a card from one player without affecting another player.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
delete from public.shared_card_recipients
where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  and shared_card_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
  and user_id = '22222222-2222-2222-2222-222222222222';

set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.shared_cards
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  if visible_count <> 0 then
    raise exception 'TEST FAILED: DM-restricted player still saw the card';
  end if;

  begin
    insert into public.shared_card_recipients (
      campaign_id, shared_card_id, user_id
    )
    values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'cccccccc-cccc-cccc-cccc-cccccccccccc',
      '22222222-2222-2222-2222-222222222222'
    );
    raise exception 'TEST FAILED: player granted itself card access';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

set local "request.jwt.claim.sub" to '33333333-3333-3333-3333-333333333333';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.shared_cards
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  if visible_count <> 1 then
    raise exception 'TEST FAILED: restricting one player affected another';
  end if;
end;
$$;

set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
insert into public.shared_card_recipients (
  campaign_id, shared_card_id, user_id
)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  '22222222-2222-2222-2222-222222222222'
);

-- A non-member sees no campaigns or cards.
set local "request.jwt.claim.sub" to '44444444-4444-4444-4444-444444444444';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.campaigns;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: non-member saw a campaign';
  end if;

  select count(*) into visible_count from public.shared_cards;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: non-member saw a shared card';
  end if;

  select count(*) into visible_count from public.campaign_members;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: non-member saw campaign members';
  end if;

  select count(*) into visible_count from public.initiative_encounters
  where active;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: non-member saw initiative';
  end if;
end;
$$;

-- Revocation hides the payload but publishes a member-readable ID-only event.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
update public.shared_cards set revoked = true
where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.shared_cards
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  if visible_count <> 0 then
    raise exception 'TEST FAILED: revoked card remained visible';
  end if;

  select count(*) into visible_count from public.card_share_events
  where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    and shared_card_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
    and event_type = 'revoked';
  if visible_count <> 1 then
    raise exception 'TEST FAILED: member did not receive a revocation event';
  end if;
end;
$$;

-- Ending combat removes the encounter from the player-readable view.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
update public.initiative_encounters
set active = false, player_state = '{"schema_version":1,"combatants":[]}'::jsonb
where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
do $$
declare
  visible_count integer;
begin
  select count(*) into visible_count from public.initiative_encounters
  where active;
  if visible_count <> 0 then
    raise exception 'TEST FAILED: ended encounter remained visible';
  end if;
end;
$$;

-- The JSON payload byte limit is enforced by Postgres.
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';
do $$
begin
  begin
    insert into public.shared_cards (campaign_id, source_card_uuid, payload)
    values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      gen_random_uuid(),
      jsonb_build_object('oversized', repeat('x', 100001))
    );
    raise exception 'TEST FAILED: oversized payload was accepted';
  exception when check_violation then
    null;
  end;
end;
$$;

rollback;
