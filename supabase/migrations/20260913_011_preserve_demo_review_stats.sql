create or replace function app_private.refresh_listing_review_stats()
returns trigger
language plpgsql
security definer
set search_path='public','app_private'
as $$
declare
  lid uuid;
  demo boolean;
begin
  lid:=coalesce(new.listing_id,old.listing_id);
  select is_demo into demo from public.listings where id=lid;
  if coalesce(demo,false) then
    return coalesce(new,old);
  end if;
  update public.listings
  set rating=(select round(avg(rating)::numeric,1) from public.reviews where listing_id=lid and status='approved'),
      review_count=(select count(*) from public.reviews where listing_id=lid and status='approved')
  where id=lid;
  return coalesce(new,old);
end $$;

revoke all on function app_private.refresh_listing_review_stats() from public,anon,authenticated;
