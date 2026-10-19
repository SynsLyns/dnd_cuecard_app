-- Break policy recursion by checking membership through narrowly scoped
-- security-definer functions owned by the database migration role.
create or replace function public.is_campaign_member(target_campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.campaign_members as cm
    where cm.campaign_id = target_campaign_id
      and cm.user_id = auth.uid()
  );
$$;

create or replace function public.is_campaign_dm(target_campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.campaigns as c
    where c.id = target_campaign_id
      and c.dm_id = auth.uid()
  );
$$;

revoke all on function public.is_campaign_member(uuid) from public, anon;
revoke all on function public.is_campaign_dm(uuid) from public, anon;
grant execute on function public.is_campaign_member(uuid) to authenticated;
grant execute on function public.is_campaign_dm(uuid) to authenticated;

drop policy if exists "Members can view campaigns they belong to" on public.campaigns;
create policy "Members can view campaigns they belong to"
  on public.campaigns
  for select
  to authenticated
  using (public.is_campaign_member(id));

drop policy if exists "Members and DMs can view campaign members" on public.campaign_members;
create policy "Members and DMs can view campaign members"
  on public.campaign_members
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_campaign_member(campaign_id)
    or public.is_campaign_dm(campaign_id)
  );

drop policy if exists "DMs can remove campaign members" on public.campaign_members;
create policy "DMs can remove campaign members"
  on public.campaign_members
  for delete
  to authenticated
  using (public.is_campaign_dm(campaign_id));

drop policy if exists "DMs can manage shared cards in their campaigns" on public.shared_cards;
create policy "DMs can manage shared cards in their campaigns"
  on public.shared_cards
  for all
  to authenticated
  using (public.is_campaign_dm(campaign_id))
  with check (public.is_campaign_dm(campaign_id));

drop policy if exists "Members can view unrevoked shared cards" on public.shared_cards;
create policy "Members can view unrevoked shared cards"
  on public.shared_cards
  for select
  to authenticated
  using (not revoked and public.is_campaign_member(campaign_id));

-- Keep the payload limit effective if a project was created from an earlier
-- version of the first migration.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.shared_cards'::regclass
      and conname = 'payload_size_limit'
  ) then
    alter table public.shared_cards
      add constraint payload_size_limit
      check (octet_length(payload::text) <= 100000);
  end if;
end;
$$;

-- Realtime applies SELECT RLS to changed rows. A member is not allowed to
-- select a revoked card, so publish a separate event containing only its IDs.
create table if not exists public.card_share_events (
  id bigint generated always as identity primary key,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  shared_card_id uuid not null,
  event_type text not null check (event_type = 'revoked'),
  created_at timestamptz not null default now()
);

create index if not exists idx_card_share_events_campaign_created
  on public.card_share_events (campaign_id, created_at desc);

alter table public.card_share_events enable row level security;

drop policy if exists "Campaign members can read card share events"
  on public.card_share_events;
create policy "Campaign members can read card share events"
  on public.card_share_events
  for select
  to authenticated
  using (
    public.is_campaign_member(campaign_id)
    or public.is_campaign_dm(campaign_id)
  );

grant select on public.card_share_events to authenticated;

create or replace function public.publish_card_revocation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.revoked = false and new.revoked = true then
    insert into public.card_share_events (
      campaign_id,
      shared_card_id,
      event_type
    )
    values (new.campaign_id, new.id, 'revoked');
  end if;
  return new;
end;
$$;

revoke all on function public.publish_card_revocation() from public, anon, authenticated;

drop trigger if exists publish_card_revocation on public.shared_cards;
create trigger publish_card_revocation
  after update of revoked on public.shared_cards
  for each row
  execute function public.publish_card_revocation();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'card_share_events'
  ) then
    alter publication supabase_realtime add table public.card_share_events;
  end if;
end;
$$;

-- Restrict the join RPC to authenticated users and remove its mutable default
-- search path.
create or replace function public.join_campaign(code text, display_name text)
returns table (
  campaign_id uuid,
  campaign_name text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_campaign public.campaigns%rowtype;
  calling_user_id uuid;
  clean_display_name text;
begin
  calling_user_id := auth.uid();
  if calling_user_id is null then
    raise exception 'Authentication required to join a campaign';
  end if;

  clean_display_name := pg_catalog.trim(coalesce(display_name, ''));
  if pg_catalog.char_length(clean_display_name) not between 1 and 40 then
    raise exception 'Display name must be between 1 and 40 characters';
  end if;

  if pg_catalog.char_length(pg_catalog.trim(coalesce(code, '')))
      not between 6 and 8 then
    raise exception 'Join code must be between 6 and 8 characters';
  end if;

  select c.* into target_campaign
  from public.campaigns as c
  where pg_catalog.upper(c.join_code) =
        pg_catalog.upper(pg_catalog.trim(code));

  if not found then
    raise exception 'Invalid join code';
  end if;

  insert into public.campaign_members (
    campaign_id,
    user_id,
    display_name,
    joined_at
  )
  values (
    target_campaign.id,
    calling_user_id,
    clean_display_name,
    pg_catalog.now()
  )
  on conflict (campaign_id, user_id)
  do update set display_name = excluded.display_name;

  return query
  select target_campaign.id, target_campaign.name;
end;
$$;

revoke all on function public.join_campaign(text, text) from public, anon;
grant execute on function public.join_campaign(text, text) to authenticated;

grant select, insert, update, delete
  on public.campaigns, public.campaign_members, public.shared_cards
  to authenticated;
