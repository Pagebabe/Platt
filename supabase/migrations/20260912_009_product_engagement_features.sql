alter table public.listings add column if not exists latitude double precision check (latitude is null or latitude between -90 and 90);
alter table public.listings add column if not exists longitude double precision check (longitude is null or longitude between -180 and 180);

alter table public.inquiries add column if not exists public_token uuid not null default gen_random_uuid();
alter table public.inquiries add column if not exists appointment_at timestamptz;
alter table public.inquiries add column if not exists appointment_note text;
create unique index if not exists inquiries_public_token_key on public.inquiries(public_token);
grant update(status,provider_notes,updated_at,appointment_at,appointment_note) on public.inquiries to authenticated;

create table if not exists public.inquiry_messages(id uuid primary key default gen_random_uuid(),inquiry_id uuid not null references public.inquiries(id) on delete cascade,sender_kind text not null check(sender_kind in ('visitor','provider','system')),message text not null check(char_length(message) between 1 and 2000),created_at timestamptz not null default now());
create index if not exists idx_inquiry_messages_inquiry_created on public.inquiry_messages(inquiry_id,created_at);
alter table public.inquiry_messages enable row level security;
create policy "messages provider select" on public.inquiry_messages for select to authenticated using (public.is_admin() or exists(select 1 from public.inquiries i join public.listings l on l.id=i.listing_id where i.id=inquiry_messages.inquiry_id and l.owner_id=(select auth.uid())));
create policy "messages provider insert" on public.inquiry_messages for insert to authenticated with check (sender_kind='provider' and (public.is_admin() or exists(select 1 from public.inquiries i join public.listings l on l.id=i.listing_id where i.id=inquiry_messages.inquiry_id and l.owner_id=(select auth.uid()))));
grant select,insert on public.inquiry_messages to authenticated;

create table if not exists public.reviews(id uuid primary key default gen_random_uuid(),inquiry_id uuid not null unique references public.inquiries(id) on delete cascade,listing_id uuid not null references public.listings(id) on delete cascade,rating smallint not null check(rating between 1 and 5),body text check(body is null or char_length(body)<=1500),status text not null default 'pending' check(status in ('pending','approved','rejected')),moderation_note text,provider_reply text check(provider_reply is null or char_length(provider_reply)<=1000),created_at timestamptz not null default now(),reviewed_at timestamptz,reviewed_by uuid references public.accounts(id) on delete set null);
create index if not exists idx_reviews_listing_status on public.reviews(listing_id,status,created_at desc);
create index if not exists idx_reviews_reviewed_by on public.reviews(reviewed_by);
alter table public.reviews enable row level security;
create policy "reviews public approved" on public.reviews for select using(status='approved' and exists(select 1 from public.listings l where l.id=reviews.listing_id and l.status='active'::public.listing_status));
create policy "reviews provider select" on public.reviews for select to authenticated using(public.is_admin() or exists(select 1 from public.listings l where l.id=reviews.listing_id and l.owner_id=(select auth.uid())));
create policy "reviews provider reply" on public.reviews for update to authenticated using(public.is_admin() or exists(select 1 from public.listings l where l.id=reviews.listing_id and l.owner_id=(select auth.uid()))) with check(public.is_admin() or exists(select 1 from public.listings l where l.id=reviews.listing_id and l.owner_id=(select auth.uid())));
grant select on public.reviews to anon,authenticated;
grant update(provider_reply) on public.reviews to authenticated;
grant update(status,moderation_note,reviewed_at,reviewed_by) on public.reviews to authenticated;

create table if not exists public.favorites(user_id uuid not null references auth.users(id) on delete cascade,listing_id uuid not null references public.listings(id) on delete cascade,created_at timestamptz not null default now(),primary key(user_id,listing_id));
create index if not exists idx_favorites_listing_id on public.favorites(listing_id);
alter table public.favorites enable row level security;
create policy "favorites self select" on public.favorites for select to authenticated using(user_id=(select auth.uid()));
create policy "favorites self insert" on public.favorites for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.listings l where l.id=favorites.listing_id and l.status='active'::public.listing_status));
create policy "favorites self delete" on public.favorites for delete to authenticated using(user_id=(select auth.uid()));
grant select,insert,delete on public.favorites to authenticated;

create table if not exists public.notifications(id uuid primary key default gen_random_uuid(),account_id uuid not null references public.accounts(id) on delete cascade,type text not null,title text not null,body text,entity_type text,entity_id uuid,read_at timestamptz,created_at timestamptz not null default now());
create index if not exists idx_notifications_account_created on public.notifications(account_id,created_at desc);
alter table public.notifications enable row level security;
create policy "notifications self select" on public.notifications for select to authenticated using(account_id=(select auth.uid()) or public.is_admin());
create policy "notifications self update" on public.notifications for update to authenticated using(account_id=(select auth.uid()) or public.is_admin()) with check(account_id=(select auth.uid()) or public.is_admin());
grant select on public.notifications to authenticated;
grant update(read_at) on public.notifications to authenticated;

create table if not exists public.analytics_events(id bigint generated always as identity primary key,event_type text not null check(event_type in ('page_view','profile_view','search','inquiry_open','inquiry_sent','favorite')),page text check(page is null or char_length(page)<=120),listing_id uuid references public.listings(id) on delete set null,created_at timestamptz not null default now());
create index if not exists idx_analytics_events_created on public.analytics_events(created_at desc);
create index if not exists idx_analytics_events_listing on public.analytics_events(listing_id,created_at desc);
alter table public.analytics_events enable row level security;
create policy "analytics public insert" on public.analytics_events for insert to anon,authenticated with check(event_type in ('page_view','profile_view','search','inquiry_open','inquiry_sent','favorite'));
create policy "analytics admin select" on public.analytics_events for select to authenticated using(public.is_admin());
grant insert on public.analytics_events to anon,authenticated;
grant select on public.analytics_events to authenticated;

create or replace function app_private.create_inquiry_impl(p_listing_id uuid,p_sender_name text,p_sender_email text,p_message text) returns table(inquiry_id uuid,public_token uuid) language plpgsql security definer set search_path='public' as $$ declare iid uuid; tok uuid; begin if p_message is null or char_length(trim(p_message))<10 or char_length(p_message)>2000 then raise exception 'invalid message'; end if; if p_sender_email is not null and char_length(p_sender_email)>254 then raise exception 'invalid email'; end if; if not exists(select 1 from public.listings where id=p_listing_id and status='active'::public.listing_status) then raise exception 'listing unavailable'; end if; if exists(select 1 from public.inquiries i where i.listing_id=p_listing_id and i.created_at>now()-interval '10 minutes' and lower(trim(i.message))=lower(trim(p_message)) and coalesce(lower(trim(i.sender_email)),'')=coalesce(lower(trim(p_sender_email)),'')) then raise exception 'duplicate inquiry'; end if; insert into public.inquiries(listing_id,sender_name,sender_email,message) values(p_listing_id,nullif(trim(p_sender_name),''),nullif(trim(p_sender_email),''),trim(p_message)) returning id,inquiries.public_token into iid,tok; insert into public.inquiry_messages(inquiry_id,sender_kind,message) values(iid,'visitor',trim(p_message)); return query select iid,tok; end $$;
revoke all on function app_private.create_inquiry_impl(uuid,text,text,text) from public;
grant usage on schema app_private to anon,authenticated;
grant execute on function app_private.create_inquiry_impl(uuid,text,text,text) to anon,authenticated;
create or replace function public.create_inquiry(p_listing_id uuid,p_sender_name text,p_sender_email text,p_message text) returns table(inquiry_id uuid,public_token uuid) language sql security invoker set search_path='public','app_private' as $$ select * from app_private.create_inquiry_impl(p_listing_id,p_sender_name,p_sender_email,p_message); $$;
grant execute on function public.create_inquiry(uuid,text,text,text) to anon,authenticated;

create or replace function app_private.get_inquiry_thread_impl(p_token uuid) returns jsonb language sql security definer set search_path='public' as $$ select jsonb_build_object('inquiry',jsonb_build_object('id',i.id,'listing_id',i.listing_id,'status',i.status,'appointment_at',i.appointment_at,'appointment_note',i.appointment_note,'created_at',i.created_at),'messages',coalesce((select jsonb_agg(jsonb_build_object('sender_kind',m.sender_kind,'message',m.message,'created_at',m.created_at) order by m.created_at) from public.inquiry_messages m where m.inquiry_id=i.id),'[]'::jsonb)) from public.inquiries i where i.public_token=p_token; $$;
revoke all on function app_private.get_inquiry_thread_impl(uuid) from public;
grant execute on function app_private.get_inquiry_thread_impl(uuid) to anon,authenticated;
create or replace function public.get_inquiry_thread(p_token uuid) returns jsonb language sql security invoker set search_path='public','app_private' as $$ select app_private.get_inquiry_thread_impl(p_token); $$;
grant execute on function public.get_inquiry_thread(uuid) to anon,authenticated;

create or replace function app_private.send_visitor_message_impl(p_token uuid,p_message text) returns uuid language plpgsql security definer set search_path='public' as $$ declare iid uuid; mid uuid; begin if p_message is null or char_length(trim(p_message))<1 or char_length(p_message)>2000 then raise exception 'invalid message'; end if; select id into iid from public.inquiries where public_token=p_token and status not in ('closed','spam'); if iid is null then raise exception 'conversation unavailable'; end if; insert into public.inquiry_messages(inquiry_id,sender_kind,message) values(iid,'visitor',trim(p_message)) returning id into mid; return mid; end $$;
revoke all on function app_private.send_visitor_message_impl(uuid,text) from public;
grant execute on function app_private.send_visitor_message_impl(uuid,text) to anon,authenticated;
create or replace function public.send_visitor_message(p_token uuid,p_message text) returns uuid language sql security invoker set search_path='public','app_private' as $$ select app_private.send_visitor_message_impl(p_token,p_message); $$;
grant execute on function public.send_visitor_message(uuid,text) to anon,authenticated;

create or replace function app_private.submit_review_impl(p_token uuid,p_rating integer,p_body text) returns uuid language plpgsql security definer set search_path='public' as $$ declare iid uuid; lid uuid; rid uuid; begin if p_rating<1 or p_rating>5 or (p_body is not null and char_length(p_body)>1500) then raise exception 'invalid review'; end if; select id,listing_id into iid,lid from public.inquiries where public_token=p_token and status='closed'; if iid is null then raise exception 'review not available'; end if; insert into public.reviews(inquiry_id,listing_id,rating,body) values(iid,lid,p_rating,nullif(trim(p_body),'')) returning id into rid; return rid; end $$;
revoke all on function app_private.submit_review_impl(uuid,integer,text) from public;
grant execute on function app_private.submit_review_impl(uuid,integer,text) to anon,authenticated;
create or replace function public.submit_review(p_token uuid,p_rating integer,p_body text) returns uuid language sql security invoker set search_path='public','app_private' as $$ select app_private.submit_review_impl(p_token,p_rating,p_body); $$;
grant execute on function public.submit_review(uuid,integer,text) to anon,authenticated;

create or replace function public.track_event(p_event_type text,p_page text default null,p_listing_id uuid default null) returns void language plpgsql security invoker set search_path='public' as $$ begin if p_event_type not in ('page_view','profile_view','search','inquiry_open','inquiry_sent','favorite') then raise exception 'invalid event'; end if; insert into public.analytics_events(event_type,page,listing_id) values(p_event_type,left(p_page,120),p_listing_id); end $$;
grant execute on function public.track_event(text,text,uuid) to anon,authenticated;

create or replace function app_private.notify_inquiry_created() returns trigger language plpgsql security definer set search_path='public' as $$ declare aid uuid; lname text; begin select owner_id,name into aid,lname from public.listings where id=new.listing_id; if aid is not null then insert into public.notifications(account_id,type,title,body,entity_type,entity_id) values(aid,'inquiry','Neue Anfrage',coalesce(new.sender_name,'Jemand')||' hat '||lname||' angefragt.','inquiry',new.id); end if; return new; end $$;
revoke all on function app_private.notify_inquiry_created() from public,anon,authenticated;
drop trigger if exists trg_notify_inquiry_created on public.inquiries;
create trigger trg_notify_inquiry_created after insert on public.inquiries for each row execute function app_private.notify_inquiry_created();

create or replace function app_private.notify_listing_review() returns trigger language plpgsql security definer set search_path='public' as $$ begin if new.owner_id is not null and (new.status is distinct from old.status or new.verified is distinct from old.verified) then insert into public.notifications(account_id,type,title,body,entity_type,entity_id) values(new.owner_id,'moderation','Profilstatus geändert','Status: '||new.status||case when new.verified then ' · verifiziert' else '' end,'listing',new.id); end if; return new; end $$;
revoke all on function app_private.notify_listing_review() from public,anon,authenticated;
drop trigger if exists trg_notify_listing_review on public.listings;
create trigger trg_notify_listing_review after update on public.listings for each row execute function app_private.notify_listing_review();

create or replace function app_private.notify_media_review() returns trigger language plpgsql security definer set search_path='public' as $$ declare aid uuid; begin if new.moderation_status is distinct from old.moderation_status then select owner_id into aid from public.listings where id=new.listing_id; if aid is not null then insert into public.notifications(account_id,type,title,body,entity_type,entity_id) values(aid,'media','Bildprüfung abgeschlossen','Status: '||new.moderation_status,'media',new.id); end if; end if; return new; end $$;
revoke all on function app_private.notify_media_review() from public,anon,authenticated;
drop trigger if exists trg_notify_media_review on public.listing_media;
create trigger trg_notify_media_review after update on public.listing_media for each row execute function app_private.notify_media_review();

create or replace function app_private.refresh_listing_review_stats() returns trigger language plpgsql security definer set search_path='public','app_private' as $$ declare lid uuid; begin lid:=coalesce(new.listing_id,old.listing_id); update public.listings set rating=(select round(avg(rating)::numeric,1) from public.reviews where listing_id=lid and status='approved'),review_count=(select count(*) from public.reviews where listing_id=lid and status='approved') where id=lid; return coalesce(new,old); end $$;
revoke all on function app_private.refresh_listing_review_stats() from public,anon,authenticated;
drop trigger if exists trg_refresh_listing_review_stats on public.reviews;
create trigger trg_refresh_listing_review_stats after insert or update or delete on public.reviews for each row execute function app_private.refresh_listing_review_stats();

update public.listings set latitude=case city when 'Köln' then 50.9375 when 'Düsseldorf' then 51.2277 when 'Bonn' then 50.7374 when 'Essen' then 51.4556 else latitude end,longitude=case city when 'Köln' then 6.9603 when 'Düsseldorf' then 6.7735 when 'Bonn' then 7.0982 when 'Essen' then 7.0116 else longitude end where is_demo=true;
