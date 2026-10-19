-- ==============================================================================
-- 0001_sharing.sql: Persistent Card Sharing Schema, RLS, and RPC
-- ==============================================================================

-- 1. Enable UUID generation if needed
create extension if not exists "pgcrypto";

-- 2. Create tables
create table if not exists campaigns (
  id uuid primary key default gen_random_uuid(),
  dm_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  join_code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists campaign_members (
  campaign_id uuid references campaigns(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  display_name text not null,
  joined_at timestamptz not null default now(),
  primary key (campaign_id, user_id)
);

create table if not exists shared_cards (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(id) on delete cascade,
  source_card_uuid uuid not null,
  payload jsonb not null,
  schema_version int not null default 1,
  version int not null default 1,
  revoked boolean not null default false,
  shared_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (campaign_id, source_card_uuid),
  constraint payload_size_limit check (octet_length(payload::text) <= 100000)
);

-- Indexes for performance
create index if not exists idx_campaigns_join_code on campaigns (upper(join_code));
create index if not exists idx_campaign_members_user on campaign_members (user_id);
create index if not exists idx_shared_cards_campaign on shared_cards (campaign_id);

-- 3. Row-Level Security (RLS) Policies

alter table campaigns enable row level security;
alter table campaign_members enable row level security;
alter table shared_cards enable row level security;

-- Campaigns Policies
create policy "DMs can manage their own campaigns"
  on campaigns
  for all
  to authenticated
  using (dm_id = auth.uid())
  with check (dm_id = auth.uid());

create policy "Members can view campaigns they belong to"
  on campaigns
  for select
  to authenticated
  using (
    exists (
      select 1 from campaign_members
      where campaign_members.campaign_id = campaigns.id
        and campaign_members.user_id = auth.uid()
    )
  );

-- Campaign Members Policies
create policy "Members and DMs can view campaign members"
  on campaign_members
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from campaigns
      where campaigns.id = campaign_members.campaign_id
        and campaigns.dm_id = auth.uid()
    )
    or exists (
      select 1 from campaign_members as cm
      where cm.campaign_id = campaign_members.campaign_id
        and cm.user_id = auth.uid()
    )
  );

create policy "DMs can remove campaign members"
  on campaign_members
  for delete
  to authenticated
  using (
    exists (
      select 1 from campaigns
      where campaigns.id = campaign_members.campaign_id
        and campaigns.dm_id = auth.uid()
    )
  );

-- Shared Cards Policies
create policy "DMs can manage shared cards in their campaigns"
  on shared_cards
  for all
  to authenticated
  using (
    exists (
      select 1 from campaigns
      where campaigns.id = shared_cards.campaign_id
        and campaigns.dm_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from campaigns
      where campaigns.id = shared_cards.campaign_id
        and campaigns.dm_id = auth.uid()
    )
  );

create policy "Members can view unrevoked shared cards"
  on shared_cards
  for select
  to authenticated
  using (
    revoked = false
    and exists (
      select 1 from campaign_members
      where campaign_members.campaign_id = shared_cards.campaign_id
        and campaign_members.user_id = auth.uid()
    )
  );

-- 4. Security Definer Join Function
create or replace function join_campaign(code text, display_name text)
returns table (
  campaign_id uuid,
  campaign_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_campaign campaigns%rowtype;
  calling_user_id uuid;
begin
  calling_user_id := auth.uid();
  if calling_user_id is null then
    raise exception 'Authentication required to join a campaign';
  end if;

  if trim(coalesce(display_name, '')) = '' then
    raise exception 'Display name cannot be empty';
  end if;

  select * into target_campaign
  from campaigns
  where upper(join_code) = upper(trim(code));

  if not found then
    raise exception 'Invalid join code';
  end if;

  insert into campaign_members (campaign_id, user_id, display_name, joined_at)
  values (target_campaign.id, calling_user_id, trim(display_name), now())
  on conflict (campaign_id, user_id)
  do update set display_name = excluded.display_name;

  return query
  select target_campaign.id, target_campaign.name;
end;
$$;

-- 5. Realtime publication
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'shared_cards'
  ) then
    alter publication supabase_realtime add table shared_cards;
  end if;
end;
$$;
