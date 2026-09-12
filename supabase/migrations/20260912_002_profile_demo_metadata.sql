-- Profile metadata used by the public discovery UI and clearly marked demo rows.
alter table public.listings alter column owner_id drop not null;
alter table public.listings add column if not exists age smallint;
alter table public.listings add column if not exists languages text[] not null default '{}';
alter table public.listings add column if not exists tags text[] not null default '{}';
alter table public.listings add column if not exists rating numeric;
alter table public.listings add column if not exists review_count integer not null default 0;
alter table public.listings add column if not exists response_time_minutes integer;
alter table public.listings add column if not exists is_demo boolean not null default false;

DO $$ begin
  if not exists(select 1 from pg_constraint where conname='listings_age_check' and conrelid='public.listings'::regclass) then
    alter table public.listings add constraint listings_age_check check(age is null or age between 18 and 99);
  end if;
  if not exists(select 1 from pg_constraint where conname='listings_rating_check' and conrelid='public.listings'::regclass) then
    alter table public.listings add constraint listings_rating_check check(rating is null or rating between 0 and 5);
  end if;
  if not exists(select 1 from pg_constraint where conname='listings_review_count_check' and conrelid='public.listings'::regclass) then
    alter table public.listings add constraint listings_review_count_check check(review_count>=0);
  end if;
  if not exists(select 1 from pg_constraint where conname='listings_response_time_minutes_check' and conrelid='public.listings'::regclass) then
    alter table public.listings add constraint listings_response_time_minutes_check check(response_time_minutes is null or response_time_minutes>=0);
  end if;
end $$;
