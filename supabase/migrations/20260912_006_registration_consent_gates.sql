alter table public.accounts add column if not exists adult_confirmed_at timestamptz;
alter table public.accounts add column if not exists privacy_accepted_at timestamptz;
alter table public.accounts add column if not exists terms_accepted_at timestamptz;

drop policy if exists "listings insert owner or admin" on public.listings;
create policy "listings insert owner or admin" on public.listings for insert to authenticated with check (
  public.is_admin() or (
    owner_id=(select auth.uid()) and exists(
      select 1 from public.accounts a
      where a.id=(select auth.uid())
        and a.adult_confirmed_at is not null
        and a.privacy_accepted_at is not null
        and a.terms_accepted_at is not null
    )
  )
);