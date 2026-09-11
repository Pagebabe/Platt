-- PENDING SECURITY MIGRATION — review before applying.
-- Purpose: close the three tables Supabase currently flags as publicly exposed.

alter table public.listing_media enable row level security;
alter table public.availability enable row level security;
alter table public.reports enable row level security;

-- Public users may only read media attached to active listings.
create policy "public media for active listings"
on public.listing_media for select
using (
  exists (
    select 1 from public.listings l
    where l.id = listing_media.listing_id and l.status = 'active'
  )
);

-- Listing owners manage their own media.
create policy "owners manage listing media"
on public.listing_media for all
using (
  exists (
    select 1 from public.listings l
    where l.id = listing_media.listing_id and l.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.listings l
    where l.id = listing_media.listing_id and l.owner_id = auth.uid()
  )
);

-- Public users may read availability for active listings.
create policy "public availability for active listings"
on public.availability for select
using (
  exists (
    select 1 from public.listings l
    where l.id = availability.listing_id and l.status = 'active'
  )
);

-- Listing owners manage availability for their own listings.
create policy "owners manage availability"
on public.availability for all
using (
  exists (
    select 1 from public.listings l
    where l.id = availability.listing_id and l.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.listings l
    where l.id = availability.listing_id and l.owner_id = auth.uid()
  )
);

-- Anyone may submit a report; reports are not publicly readable.
create policy "public create reports"
on public.reports for insert
with check (true);

-- Admin accounts may review and update reports.
create policy "admins manage reports"
on public.reports for all
using (
  exists (
    select 1 from public.accounts a
    where a.id = auth.uid() and a.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.accounts a
    where a.id = auth.uid() and a.role = 'admin'
  )
);
