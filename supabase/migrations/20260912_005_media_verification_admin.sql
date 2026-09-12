insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('listing-media','listing-media',false,8388608,array['image/jpeg','image/png','image/webp']::text[])
on conflict (id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

alter table public.listing_media add column if not exists is_cover boolean not null default false;
alter table public.listing_media add column if not exists moderation_note text;
alter table public.listing_media add column if not exists reviewed_at timestamptz;
alter table public.listing_media add column if not exists reviewed_by uuid references public.accounts(id) on delete set null;
alter table public.listing_media add column if not exists mime_type text;
alter table public.listing_media add column if not exists size_bytes bigint check (size_bytes is null or size_bytes between 1 and 8388608);
create unique index if not exists listing_media_one_cover on public.listing_media(listing_id) where is_cover;

alter table public.listings add column if not exists moderation_reason text;
alter table public.listings add column if not exists reviewed_at timestamptz;
alter table public.listings add column if not exists reviewed_by uuid references public.accounts(id) on delete set null;
alter table public.listings add column if not exists suspended_at timestamptz;

alter table public.reports add column if not exists resolution_note text;
alter table public.reports add column if not exists resolved_at timestamptz;
alter table public.reports add column if not exists resolved_by uuid references public.accounts(id) on delete set null;

create table if not exists public.verification_requests (
 id uuid primary key default gen_random_uuid(),
 account_id uuid not null references public.accounts(id) on delete cascade,
 listing_id uuid references public.listings(id) on delete cascade,
 kind text not null default 'identity' check (kind in ('identity','phone','profile')),
 status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
 provider_note text,
 admin_note text,
 submitted_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references public.accounts(id) on delete set null
);
create unique index if not exists verification_one_pending_kind on public.verification_requests(account_id,coalesce(listing_id,'00000000-0000-0000-0000-000000000000'::uuid),kind) where status='pending';
alter table public.verification_requests enable row level security;
drop policy if exists "verification select own admin" on public.verification_requests;
create policy "verification select own admin" on public.verification_requests for select to authenticated using (account_id=(select auth.uid()) or public.is_admin());
drop policy if exists "verification insert own" on public.verification_requests;
create policy "verification insert own" on public.verification_requests for insert to authenticated with check (account_id=(select auth.uid()) and status='pending' and reviewed_at is null and reviewed_by is null);
drop policy if exists "verification admin update" on public.verification_requests;
create policy "verification admin update" on public.verification_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
grant select,insert,update on public.verification_requests to authenticated;

create table if not exists public.moderation_audit (
 id bigint generated always as identity primary key,
 actor_id uuid references public.accounts(id) on delete set null,
 entity_type text not null,
 entity_id uuid,
 action text not null,
 before_state jsonb,
 after_state jsonb,
 created_at timestamptz not null default now()
);
alter table public.moderation_audit enable row level security;
drop policy if exists "audit admin select" on public.moderation_audit;
create policy "audit admin select" on public.moderation_audit for select to authenticated using (public.is_admin());
grant select on public.moderation_audit to authenticated;

create or replace function public.enforce_listing_moderation_fields()
returns trigger language plpgsql security definer set search_path='public','app_private' as $$
begin
  new.updated_at := now();
  if app_private.is_admin_impl() then
    if new.status is distinct from old.status or new.verified is distinct from old.verified then
      new.reviewed_at := now(); new.reviewed_by := (select auth.uid());
    end if;
    if new.status='active'::public.listing_status and old.status is distinct from new.status and new.published_at is null then new.published_at:=now(); end if;
    if new.status='paused'::public.listing_status and old.status is distinct from new.status then new.suspended_at:=now();
    elsif old.status='paused'::public.listing_status and new.status is distinct from old.status then new.suspended_at:=null; end if;
    return new;
  end if;
  if tg_op='INSERT' then
    new.status:='draft'::public.listing_status; new.verified:=false; new.published_at:=null; new.moderation_reason:=null; new.reviewed_at:=null; new.reviewed_by:=null; new.suspended_at:=null;
  else
    new.reviewed_at:=old.reviewed_at; new.reviewed_by:=old.reviewed_by; new.moderation_reason:=old.moderation_reason; new.suspended_at:=old.suspended_at;
    if new.name is distinct from old.name or new.category is distinct from old.category or new.city is distinct from old.city or new.district is distinct from old.district or new.description is distinct from old.description or new.price_from is distinct from old.price_from then
      new.status:='pending'::public.listing_status; new.verified:=false;
    else
      new.status:=old.status; new.verified:=old.verified; new.published_at:=old.published_at;
    end if;
  end if;
  return new;
end; $$;

create or replace function public.enforce_listing_media_fields()
returns trigger language plpgsql security definer set search_path='public','app_private' as $$
begin
  if app_private.is_admin_impl() then return new; end if;
  if tg_op='INSERT' then
    new.moderation_status:='pending'; new.moderation_note:=null; new.reviewed_at:=null; new.reviewed_by:=null;
  else
    new.listing_id:=old.listing_id; new.storage_path:=old.storage_path; new.mime_type:=old.mime_type; new.size_bytes:=old.size_bytes;
    new.moderation_status:=old.moderation_status; new.moderation_note:=old.moderation_note; new.reviewed_at:=old.reviewed_at; new.reviewed_by:=old.reviewed_by;
  end if;
  return new;
end; $$;
drop trigger if exists trg_enforce_listing_media_fields on public.listing_media;
create trigger trg_enforce_listing_media_fields before insert or update on public.listing_media for each row execute function public.enforce_listing_media_fields();

drop policy if exists "media select public owner admin" on public.listing_media;
create policy "media select public owner admin" on public.listing_media for select using (
  public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.owner_id=(select auth.uid())) or
  (moderation_status='approved' and exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.status='active'::public.listing_status))
);
grant select on public.listing_media to anon;
grant select,insert,update,delete on public.listing_media to authenticated;

drop policy if exists "listing media upload own folder" on storage.objects;
create policy "listing media upload own folder" on storage.objects for insert to authenticated with check (
  bucket_id='listing-media' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.listings l where l.id::text=(storage.foldername(name))[2] and l.owner_id=(select auth.uid()))
);
drop policy if exists "listing media read approved or owner" on storage.objects;
create policy "listing media read approved or owner" on storage.objects for select to anon,authenticated using (
  bucket_id='listing-media' and (
    public.is_admin() or (storage.foldername(name))[1]=(select auth.uid())::text or
    exists(select 1 from public.listing_media m join public.listings l on l.id=m.listing_id where m.storage_path=name and m.moderation_status='approved' and l.status='active'::public.listing_status)
  )
);
drop policy if exists "listing media delete owner admin" on storage.objects;
create policy "listing media delete owner admin" on storage.objects for delete to authenticated using (
  bucket_id='listing-media' and (public.is_admin() or (storage.foldername(name))[1]=(select auth.uid())::text)
);

create or replace function app_private.audit_admin_update()
returns trigger language plpgsql security definer set search_path='public','app_private' as $$
declare eid uuid; act text;
begin
  if not app_private.is_admin_impl() then return new; end if;
  if tg_table_name='listings' then eid:=new.id; act:='listing_update';
  elsif tg_table_name='listing_media' then eid:=new.id; act:='media_update';
  elsif tg_table_name='reports' then eid:=new.id; act:='report_update';
  elsif tg_table_name='accounts' then eid:=new.id; act:='account_update';
  elsif tg_table_name='verification_requests' then eid:=new.id; act:='verification_update';
  else return new; end if;
  insert into public.moderation_audit(actor_id,entity_type,entity_id,action,before_state,after_state)
  values ((select auth.uid()),tg_table_name,eid,act,to_jsonb(old),to_jsonb(new));
  return new;
end; $$;
revoke all on function app_private.audit_admin_update() from public,anon,authenticated;
drop trigger if exists trg_audit_admin_listing on public.listings;
create trigger trg_audit_admin_listing after update on public.listings for each row execute function app_private.audit_admin_update();
drop trigger if exists trg_audit_admin_media on public.listing_media;
create trigger trg_audit_admin_media after update on public.listing_media for each row execute function app_private.audit_admin_update();
drop trigger if exists trg_audit_admin_report on public.reports;
create trigger trg_audit_admin_report after update on public.reports for each row execute function app_private.audit_admin_update();
drop trigger if exists trg_audit_admin_account on public.accounts;
create trigger trg_audit_admin_account after update on public.accounts for each row execute function app_private.audit_admin_update();
drop trigger if exists trg_audit_admin_verification on public.verification_requests;
create trigger trg_audit_admin_verification after update on public.verification_requests for each row execute function app_private.audit_admin_update();
