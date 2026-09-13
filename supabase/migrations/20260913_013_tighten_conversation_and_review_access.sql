drop policy if exists "messages provider insert" on public.inquiry_messages;
create policy "messages provider insert" on public.inquiry_messages for insert to authenticated
with check(
  sender_kind='provider' and (
    public.is_admin() or exists(
      select 1 from public.inquiries i
      join public.listings l on l.id=i.listing_id
      where i.id=inquiry_messages.inquiry_id
        and l.owner_id=(select auth.uid())
        and i.status not in ('closed','spam')
    )
  )
);

drop policy if exists "reviews provider select" on public.reviews;
create policy "reviews provider select" on public.reviews for select to authenticated
using(
  public.is_admin() or (
    status='approved' and exists(
      select 1 from public.listings l
      where l.id=reviews.listing_id and l.owner_id=(select auth.uid())
    )
  )
);

drop policy if exists "reviews provider reply" on public.reviews;
create policy "reviews provider reply" on public.reviews for update to authenticated
using(
  public.is_admin() or (
    status='approved' and exists(
      select 1 from public.listings l
      where l.id=reviews.listing_id and l.owner_id=(select auth.uid())
    )
  )
)
with check(
  public.is_admin() or (
    status='approved' and exists(
      select 1 from public.listings l
      where l.id=reviews.listing_id and l.owner_id=(select auth.uid())
    )
  )
);

create or replace function app_private.notify_visitor_message()
returns trigger
language plpgsql
security definer
set search_path='public'
as $$
declare
  aid uuid;
  lname text;
  msg_count integer;
begin
  if new.sender_kind<>'visitor' then return new; end if;
  select count(*) into msg_count from public.inquiry_messages where inquiry_id=new.inquiry_id;
  if msg_count<=1 then return new; end if;
  select l.owner_id,l.name into aid,lname
  from public.inquiries i join public.listings l on l.id=i.listing_id
  where i.id=new.inquiry_id;
  if aid is not null then
    insert into public.notifications(account_id,type,title,body,entity_type,entity_id)
    values(aid,'message','Neue Nachricht',coalesce(lname,'Profil')||': neue Besuchernachricht.','inquiry',new.inquiry_id);
  end if;
  return new;
end $$;

revoke all on function app_private.notify_visitor_message() from public,anon,authenticated;
drop trigger if exists trg_notify_visitor_message on public.inquiry_messages;
create trigger trg_notify_visitor_message after insert on public.inquiry_messages for each row execute function app_private.notify_visitor_message();
