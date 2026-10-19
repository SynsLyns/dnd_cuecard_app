-- ==============================================================================
-- sharing_rls_test.sql: SQL Test Script for Sharing RLS & Permissions
-- Run in Supabase SQL Editor or via supabase test db
-- ==============================================================================

begin;

-- Create mock users in auth.users if not already present
do $$
declare
  dm_id uuid := '11111111-1111-1111-1111-111111111111';
  player_a_id uuid := '22222222-2222-2222-2222-222222222222';
  player_b_id uuid := '33333333-3333-3333-3333-333333333333';
  non_member_id uuid := '44444444-4444-4444-4444-444444444444';
begin
  -- Ensure test users exist in auth.users
  insert into auth.users (id, email)
  values 
    (dm_id, 'dm@test.local'),
    (player_a_id, 'player_a@test.local'),
    (player_b_id, 'player_b@test.local'),
    (non_member_id, 'stranger@test.local')
  on conflict (id) do nothing;
end;
$$;

-- 1. Test DM Creating Campaigns
set local role authenticated;
set local "request.jwt.claim.sub" to '11111111-1111-1111-1111-111111111111';

insert into campaigns (id, dm_id, name, join_code)
values 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Campaign A', 'CAMP01'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Campaign B', 'CAMP02');

-- DM Shares a card to Campaign A
insert into shared_cards (id, campaign_id, source_card_uuid, payload)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '99999999-9999-9999-9999-999999999999',
  '{"title": "Fireball", "notes": "DM test card"}'::jsonb
);

-- 2. Test Player A Joining Campaign A via RPC
set local "request.jwt.claim.sub" to '22222222-2222-2222-2222-222222222222';
select * from join_campaign('CAMP01', 'Player Alpha');

-- Player A can view shared cards in Campaign A
do $$
declare
  card_count int;
begin
  select count(*) into card_count from shared_cards where campaign_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if card_count <> 1 then
    raise exception 'TEST FAILED: Player A should see 1 card in Campaign A, found %', card_count;
  end if;
end;
$$;

-- 3. Test: Player A cannot write/insert into shared_cards
do $$
begin
  begin
    insert into shared_cards (campaign_id, source_card_uuid, payload)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', gen_random_uuid(), '{"title": "Hacked"}'::jsonb);
    raise exception 'TEST FAILED: Player A was able to insert into shared_cards!';
  exception when insufficient_privilege or integrity_constraint_violation then
    -- Expected behavior: RLS blocks player insert
    null;
  end;
end;
$$;

-- 4. Test: Player A cannot see Campaign B or its cards
do $$
declare
  b_count int;
begin
  select count(*) into b_count from campaigns where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if b_count <> 0 then
    raise exception 'TEST FAILED: Player A should not see Campaign B, found %', b_count;
  end if;
end;
$$;

-- 5. Test: Non-member cannot see any cards
set local "request.jwt.claim.sub" to '44444444-4444-4444-4444-444444444444';
do $$
declare
  nm_count int;
begin
  select count(*) into nm_count from shared_cards;
  if nm_count <> 0 then
    raise exception 'TEST FAILED: Non-member should see 0 shared cards, found %', nm_count;
  end if;
end;
$$;

rollback;
-- Tests completed successfully!
