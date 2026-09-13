create table if not exists public.customer_profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  adult_confirmed_at timestamptz not null,
  privacy_accepted_at timestamptz not null,
  terms_accepted_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.customer_profiles enable row level security;
drop policy if exists "customer profile self select" on public.customer_profiles;
create policy "customer profile self select" on public.customer_profiles for select to authenticated using(id=(select auth.uid()));
revoke all on public.customer_profiles from anon,authenticated;
grant select on public.customer_profiles to authenticated;

create or replace function app_private.bootstrap_customer_profile()
returns trigger
language plpgsql
security definer
set search_path='public','auth','app_private'
as $$
begin
  if coalesce(new.raw_user_meta_data->>'account_type','')='customer' then
    insert into public.customer_profiles(id,adult_confirmed_at,privacy_accepted_at,terms_accepted_at)
    values(new.id,now(),now(),now())
    on conflict(id) do nothing;
  end if;
  return new;
end $$;

revoke all on function app_private.bootstrap_customer_profile() from public,anon,authenticated;
drop trigger if exists trg_bootstrap_customer_profile on auth.users;
create trigger trg_bootstrap_customer_profile after insert on auth.users for each row execute function app_private.bootstrap_customer_profile();

insert into public.customer_profiles(id,adult_confirmed_at,privacy_accepted_at,terms_accepted_at)
select u.id,coalesce(u.created_at,now()),coalesce(u.created_at,now()),coalesce(u.created_at,now())
from auth.users u
where coalesce(u.raw_user_meta_data->>'account_type','')='customer'
on conflict(id) do nothing;
