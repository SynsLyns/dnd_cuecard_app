-- Fresh-project schema for campaigns, shared cards, and per-player card access.
-- Apply this file once to a new Supabase project.

create extension if not exists pgcrypto;

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  dm_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  join_code text not null unique,
  created_at timestamptz not null default now()
);

create table public.campaign_members (
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  joined_at timestamptz not null default now(),
  primary key (campaign_id, user_id)
);

create table public.shared_cards (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  source_card_uuid uuid not null,
  payload jsonb not null,
  schema_version integer not null default 1,
  version integer not null default 1,
  revoked boolean not null default false,
  shared_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (campaign_id, source_card_uuid),
  unique (id, campaign_id),
  constraint payload_size_limit check (octet_length(payload::text) <= 100000)
);

create index idx_campaigns_join_code on public.campaigns (upper(join_code));
create index idx_campaign_members_user on public.campaign_members (user_id);
create index idx_shared_cards_campaign on public.shared_cards (campaign_id);

create table public.shared_card_recipients (
  campaign_id uuid not null,
  shared_card_id uuid not null,
  user_id uuid not null,
  primary key (shared_card_id, user_id),
  foreign key (campaign_id, user_id)
    references public.campaign_members(campaign_id, user_id)
    on delete cascade,
  foreign key (shared_card_id, campaign_id)
    references public.shared_cards(id, campaign_id)
    on delete cascade
);

create index idx_shared_card_recipients_campaign_user
  on public.shared_card_recipients (campaign_id, user_id);

create table public.card_share_events (
  id bigint generated always as identity primary key,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  shared_card_id uuid not null,
  event_type text not null check (event_type in ('revoked', 'access_changed')),
  created_at timestamptz not null default now()
);

create index idx_card_share_events_campaign_created
  on public.card_share_events (campaign_id, created_at desc);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'shared-card-icons',
  'shared-card-icons',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp']
);

alter table public.campaigns enable row level security;
alter table public.campaign_members enable row level security;
alter table public.shared_cards enable row level security;
alter table public.shared_card_recipients enable row level security;
alter table public.card_share_events enable row level security;

-- These narrowly scoped helpers avoid recursive policy checks.
create function public.is_registered_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users as u
    where u.id = auth.uid()
      and not u.is_anonymous
  );
$$;

create function public.is_campaign_member(target_campaign_id uuid)
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
  ) and public.is_registered_user();
$$;

create function public.is_campaign_dm(target_campaign_id uuid)
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
  ) and public.is_registered_user();
$$;

revoke all on function public.is_registered_user() from public, anon;
revoke all on function public.is_campaign_member(uuid) from public, anon;
revoke all on function public.is_campaign_dm(uuid) from public, anon;
grant execute on function public.is_registered_user() to authenticated;
grant execute on function public.is_campaign_member(uuid) to authenticated;
grant execute on function public.is_campaign_dm(uuid) to authenticated;

create policy "DMs can manage their own campaigns"
  on public.campaigns
  for all
  to authenticated
  using (public.is_registered_user() and dm_id = auth.uid())
  with check (public.is_registered_user() and dm_id = auth.uid());

create policy "Members can view campaigns they belong to"
  on public.campaigns
  for select
  to authenticated
  using (public.is_campaign_member(id));

create policy "Members and DMs can view campaign members"
  on public.campaign_members
  for select
  to authenticated
  using (
    (public.is_registered_user() and user_id = auth.uid())
    or public.is_campaign_member(campaign_id)
    or public.is_campaign_dm(campaign_id)
  );

create policy "DMs can remove campaign members"
  on public.campaign_members
  for delete
  to authenticated
  using (public.is_campaign_dm(campaign_id));

create policy "DMs can manage shared cards in their campaigns"
  on public.shared_cards
  for all
  to authenticated
  using (public.is_campaign_dm(campaign_id))
  with check (public.is_campaign_dm(campaign_id));

create policy "Players can view assigned unrevoked shared cards"
  on public.shared_cards
  for select
  to authenticated
  using (
    not revoked
    and exists (
      select 1
      from public.shared_card_recipients as recipient
      where recipient.shared_card_id = shared_cards.id
        and recipient.campaign_id = shared_cards.campaign_id
        and recipient.user_id = auth.uid()
    )
    and public.is_registered_user()
  );

create policy "DMs manage shared card recipients"
  on public.shared_card_recipients
  for all
  to authenticated
  using (public.is_campaign_dm(campaign_id))
  with check (public.is_campaign_dm(campaign_id));

create policy "Players can view their own shared card recipients"
  on public.shared_card_recipients
  for select
  to authenticated
  using (
    user_id = auth.uid()
    and public.is_campaign_member(campaign_id)
  );

create policy "Campaign members can read card share events"
  on public.card_share_events
  for select
  to authenticated
  using (
    public.is_campaign_member(campaign_id)
    or public.is_campaign_dm(campaign_id)
  );

create policy "DMs manage shared card icons"
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'shared-card-icons'
    and public.is_campaign_dm(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'shared-card-icons'
    and public.is_campaign_dm(((storage.foldername(name))[1])::uuid)
  );

create policy "Players can read assigned shared card icons"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'shared-card-icons'
    and exists (
      select 1
      from public.shared_cards as sc
      join public.shared_card_recipients as recipient
        on recipient.shared_card_id = sc.id
       and recipient.campaign_id = sc.campaign_id
      where sc.campaign_id::text = (storage.foldername(name))[1]
        and sc.source_card_uuid::text = storage.filename(name)
        and not sc.revoked
        and recipient.user_id = auth.uid()
    )
    and public.is_registered_user()
  );

grant select, insert, update, delete
  on public.campaigns, public.campaign_members, public.shared_cards,
     public.shared_card_recipients
  to authenticated;
grant select on public.card_share_events to authenticated;

create function public.join_campaign(code text, display_name text)
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
  if calling_user_id is null or not public.is_registered_user() then
    raise exception 'Sign in with a registered account to join a campaign';
  end if;

  clean_display_name := pg_catalog.btrim(coalesce(display_name, ''));
  if pg_catalog.char_length(clean_display_name) not between 1 and 40 then
    raise exception 'Display name must be between 1 and 40 characters';
  end if;

  if pg_catalog.char_length(pg_catalog.btrim(coalesce(code, '')))
      not between 6 and 8 then
    raise exception 'Join code must be between 6 and 8 characters';
  end if;

  select c.* into target_campaign
  from public.campaigns as c
  where pg_catalog.upper(c.join_code) =
        pg_catalog.upper(pg_catalog.btrim(code));

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
  on conflict on constraint campaign_members_pkey
  do update set display_name = excluded.display_name;

  return query
  select target_campaign.id, target_campaign.name;
end;
$$;

revoke all on function public.join_campaign(text, text) from public, anon;
grant execute on function public.join_campaign(text, text) to authenticated;

create function public.publish_card_revocation()
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

revoke all on function public.publish_card_revocation()
  from public, anon, authenticated;
create trigger publish_card_revocation
  after update of revoked on public.shared_cards
  for each row
  execute function public.publish_card_revocation();

create function public.publish_card_recipient_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    insert into public.card_share_events (
      campaign_id,
      shared_card_id,
      event_type
    )
    values (old.campaign_id, old.shared_card_id, 'access_changed');
    return old;
  end if;

  insert into public.card_share_events (
    campaign_id,
    shared_card_id,
    event_type
  )
  values (new.campaign_id, new.shared_card_id, 'access_changed');
  return new;
end;
$$;

revoke all on function public.publish_card_recipient_change()
  from public, anon, authenticated;
create trigger publish_card_recipient_change
  after insert or delete on public.shared_card_recipients
  for each row
  execute function public.publish_card_recipient_change();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_cards'
  ) then
    alter publication supabase_realtime add table public.shared_cards;
  end if;

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
