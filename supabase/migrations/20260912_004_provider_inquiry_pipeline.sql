alter table public.inquiries add column if not exists provider_notes text;
alter table public.inquiries add column if not exists updated_at timestamptz not null default now();

DO $$ begin
  if not exists(select 1 from pg_constraint where conname='inquiries_status_check' and conrelid='public.inquiries'::regclass) then
    alter table public.inquiries add constraint inquiries_status_check check(status in ('new','read','qualified','appointment','closed','spam'));
  end if;
end $$;

create or replace function public.touch_inquiry_updated_at() returns trigger language plpgsql set search_path=public as $$
begin new.updated_at:=now(); return new; end;
$$;

drop trigger if exists trg_touch_inquiry_updated_at on public.inquiries;
create trigger trg_touch_inquiry_updated_at before update on public.inquiries for each row execute function public.touch_inquiry_updated_at();

drop policy if exists "inquiries update owner or admin" on public.inquiries;
create policy "inquiries update owner or admin" on public.inquiries for update
using(public.is_admin() or exists(select 1 from public.listings l where l.id=inquiries.listing_id and l.owner_id=(select auth.uid())))
with check(public.is_admin() or exists(select 1 from public.listings l where l.id=inquiries.listing_id and l.owner_id=(select auth.uid())));

revoke update on public.inquiries from authenticated;
grant update(status,provider_notes,updated_at) on public.inquiries to authenticated;
