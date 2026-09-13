drop policy if exists "reviews public approved" on public.reviews;
drop policy if exists "reviews provider select" on public.reviews;

create policy "reviews select public owner admin" on public.reviews for select
using(
  public.is_admin()
  or (
    status='approved' and exists(
      select 1 from public.listings l
      where l.id=reviews.listing_id
        and (l.status='active'::public.listing_status or l.owner_id=(select auth.uid()))
    )
  )
);
