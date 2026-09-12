-- Reconcile production security state so a fresh database can reproduce the live beta.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create or replace function app_private.is_admin_impl()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.accounts a where a.id=(select auth.uid()) and a.role='admin'::public.account_role);
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public,app_private as $$
  select app_private.is_admin_impl();
$$;

create or replace function app_private.activate_boost_impl(p_listing_id uuid,p_credits integer default 5,p_hours integer default 3)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_uid uuid := (select auth.uid()); v_balance integer; v_campaign uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_credits<=0 or p_hours<=0 or p_hours>24 then raise exception 'invalid boost'; end if;
  if not exists(select 1 from public.listings where id=p_listing_id and owner_id=v_uid and status='active'::public.listing_status) then raise exception 'listing not active or not owned'; end if;
  select balance into v_balance from public.credit_wallets where account_id=v_uid for update;
  if coalesce(v_balance,0)<p_credits then raise exception 'insufficient credits'; end if;
  update public.credit_wallets set balance=balance-p_credits,updated_at=now() where account_id=v_uid;
  insert into public.credit_transactions(account_id,amount,reason) values(v_uid,-p_credits,'boost');
  insert into public.campaigns(listing_id,type,credits_spent,starts_at,ends_at,active)
  values(p_listing_id,'boost'::public.campaign_type,p_credits,now(),now()+make_interval(hours=>p_hours),true)
  returning id into v_campaign;
  return v_campaign;
end; $$;

create or replace function public.activate_boost(p_listing_id uuid,p_credits integer default 5,p_hours integer default 3)
returns uuid language sql security definer set search_path=public,app_private as $$
  select app_private.activate_boost_impl(p_listing_id,p_credits,p_hours);
$$;

revoke execute on all functions in schema app_private from public, anon, authenticated;
grant execute on function public.is_admin() to anon, authenticated;
revoke execute on function public.activate_boost(uuid,integer,integer) from public, anon;
grant execute on function public.activate_boost(uuid,integer,integer) to authenticated;

create or replace function public.enforce_account_security_fields() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if public.is_admin() then return new; end if;
  if tg_op='INSERT' then new.role:='provider'::public.account_role; new.phone_verified:=false;
  else new.role:=old.role; new.phone_verified:=old.phone_verified; end if;
  return new;
end; $$;

create or replace function public.enforce_listing_moderation_fields() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if public.is_admin() then
    if tg_op='UPDATE' and new.status='active'::public.listing_status and old.status is distinct from new.status and new.published_at is null then new.published_at:=now(); end if;
    return new;
  end if;
  if tg_op='INSERT' then new.status:='draft'::public.listing_status; new.verified:=false; new.published_at:=null;
  else new.status:=old.status; new.verified:=old.verified; new.published_at:=old.published_at; end if;
  return new;
end; $$;

create or replace function public.prevent_duplicate_inquiry() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if exists(select 1 from public.inquiries i where i.listing_id=new.listing_id and i.created_at>now()-interval '10 minutes' and lower(trim(i.message))=lower(trim(new.message)) and coalesce(lower(trim(i.sender_email)),'')=coalesce(lower(trim(new.sender_email)),'')) then raise exception 'duplicate inquiry'; end if;
  return new;
end; $$;

create or replace function public.bootstrap_account_defaults() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.credit_wallets(account_id,balance) values(new.id,20) on conflict(account_id) do nothing;
  insert into public.subscriptions(account_id,plan,status) values(new.id,'free','active');
  return new;
end; $$;

drop trigger if exists trg_enforce_account_security_fields on public.accounts;
create trigger trg_enforce_account_security_fields before insert or update on public.accounts for each row execute function public.enforce_account_security_fields();
drop trigger if exists trg_bootstrap_account_defaults on public.accounts;
create trigger trg_bootstrap_account_defaults after insert on public.accounts for each row execute function public.bootstrap_account_defaults();
drop trigger if exists trg_enforce_listing_moderation on public.listings;
create trigger trg_enforce_listing_moderation before insert or update on public.listings for each row execute function public.enforce_listing_moderation_fields();
drop trigger if exists trg_prevent_duplicate_inquiry on public.inquiries;
create trigger trg_prevent_duplicate_inquiry before insert on public.inquiries for each row execute function public.prevent_duplicate_inquiry();

alter table public.listing_media enable row level security;
alter table public.availability enable row level security;
alter table public.reports enable row level security;

DO $$ DECLARE r record; BEGIN
  FOR r IN select schemaname,tablename,policyname from pg_policies where schemaname='public' LOOP
    execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename);
  END LOOP;
END $$;

create policy "accounts select self or admin" on public.accounts for select using(id=(select auth.uid()) or public.is_admin());
create policy "accounts insert self" on public.accounts for insert with check(id=(select auth.uid()));
create policy "accounts update self or admin" on public.accounts for update using(id=(select auth.uid()) or public.is_admin()) with check(id=(select auth.uid()) or public.is_admin());
create policy "accounts delete admin" on public.accounts for delete using(public.is_admin());
create policy "listings select public owner admin" on public.listings for select using(status='active'::public.listing_status or owner_id=(select auth.uid()) or public.is_admin());
create policy "listings insert owner or admin" on public.listings for insert with check(owner_id=(select auth.uid()) or public.is_admin());
create policy "listings update owner or admin" on public.listings for update using(owner_id=(select auth.uid()) or public.is_admin()) with check(owner_id=(select auth.uid()) or public.is_admin());
create policy "listings delete owner or admin" on public.listings for delete using(owner_id=(select auth.uid()) or public.is_admin());
create policy "media select public owner admin" on public.listing_media for select using(public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and (l.status='active'::public.listing_status or l.owner_id=(select auth.uid()))));
create policy "media insert owner admin" on public.listing_media for insert with check(public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.owner_id=(select auth.uid())));
create policy "media update owner admin" on public.listing_media for update using(public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.owner_id=(select auth.uid()))) with check(public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.owner_id=(select auth.uid())));
create policy "media delete owner admin" on public.listing_media for delete using(public.is_admin() or exists(select 1 from public.listings l where l.id=listing_media.listing_id and l.owner_id=(select auth.uid())));
create policy "availability select public owner admin" on public.availability for select using(public.is_admin() or exists(select 1 from public.listings l where l.id=availability.listing_id and (l.status='active'::public.listing_status or l.owner_id=(select auth.uid()))));
create policy "availability insert owner admin" on public.availability for insert with check(public.is_admin() or exists(select 1 from public.listings l where l.id=availability.listing_id and l.owner_id=(select auth.uid())));
create policy "availability update owner admin" on public.availability for update using(public.is_admin() or exists(select 1 from public.listings l where l.id=availability.listing_id and l.owner_id=(select auth.uid()))) with check(public.is_admin() or exists(select 1 from public.listings l where l.id=availability.listing_id and l.owner_id=(select auth.uid())));
create policy "availability delete owner admin" on public.availability for delete using(public.is_admin() or exists(select 1 from public.listings l where l.id=availability.listing_id and l.owner_id=(select auth.uid())));
create policy "inquiries public insert active listing" on public.inquiries for insert with check(exists(select 1 from public.listings l where l.id=inquiries.listing_id and l.status='active'::public.listing_status));
create policy "inquiries select owner or admin" on public.inquiries for select using(public.is_admin() or exists(select 1 from public.listings l where l.id=inquiries.listing_id and l.owner_id=(select auth.uid())));
create policy "subscriptions select self or admin" on public.subscriptions for select using(account_id=(select auth.uid()) or public.is_admin());
create policy "wallet select self or admin" on public.credit_wallets for select using(account_id=(select auth.uid()) or public.is_admin());
create policy "transactions select self or admin" on public.credit_transactions for select using(account_id=(select auth.uid()) or public.is_admin());
create policy "campaigns select public owner admin" on public.campaigns for select using((active=true and starts_at<=now() and ends_at>now()) or public.is_admin() or exists(select 1 from public.listings l where l.id=campaigns.listing_id and l.owner_id=(select auth.uid())));
create policy "reports public insert" on public.reports for insert with check(listing_id is null or exists(select 1 from public.listings l where l.id=reports.listing_id and l.status='active'::public.listing_status));
create policy "reports admin select" on public.reports for select using(public.is_admin());
create policy "reports admin update" on public.reports for update using(public.is_admin()) with check(public.is_admin());
create policy "reports admin delete" on public.reports for delete using(public.is_admin());

revoke all on all tables in schema public from anon, authenticated;
grant select on public.listings,public.listing_media,public.availability,public.campaigns to anon;
grant insert on public.inquiries,public.reports to anon;
grant select,insert,update,delete on public.accounts,public.listings,public.listing_media,public.availability to authenticated;
grant select,insert on public.inquiries to authenticated;
grant select on public.subscriptions,public.credit_wallets,public.credit_transactions,public.campaigns to authenticated;
grant select,insert,update,delete on public.reports to authenticated;

create index if not exists idx_listings_owner_id on public.listings(owner_id);
create index if not exists idx_listing_media_listing_id on public.listing_media(listing_id);
create index if not exists idx_availability_listing_id on public.availability(listing_id);
create index if not exists idx_inquiries_listing_id on public.inquiries(listing_id);
create index if not exists idx_inquiries_created_at on public.inquiries(created_at desc);
create index if not exists idx_subscriptions_account_id on public.subscriptions(account_id);
create index if not exists idx_credit_transactions_account_id on public.credit_transactions(account_id);
create index if not exists idx_campaigns_listing_id on public.campaigns(listing_id);
create index if not exists idx_campaigns_active_window on public.campaigns(active,starts_at,ends_at);
create index if not exists idx_reports_listing_id on public.reports(listing_id);
create index if not exists idx_listings_public_search on public.listings(status,city,category,available_today,published_at desc);
