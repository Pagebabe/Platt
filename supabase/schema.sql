-- LIVARA beta schema (Supabase/Postgres)
create extension if not exists pgcrypto;

create type public.account_role as enum ('provider','studio','admin');
create type public.listing_status as enum ('draft','pending','active','paused','rejected');
create type public.subscription_plan as enum ('free','pro','premium','business');
create type public.campaign_type as enum ('boost','sponsored','featured','banner');

create table public.accounts (
  id uuid primary key references auth.users(id) on delete cascade,
  role account_role not null default 'provider',
  display_name text not null,
  phone text,
  phone_verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.accounts(id) on delete cascade,
  slug text unique not null,
  name text not null,
  category text not null,
  city text not null,
  district text,
  description text,
  price_from integer,
  verified boolean not null default false,
  available_today boolean not null default false,
  status listing_status not null default 'draft',
  published_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.listing_media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  moderation_status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.availability (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  weekday smallint check (weekday between 0 and 6),
  starts_at time,
  ends_at time,
  is_available boolean not null default true
);

create table public.inquiries (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  sender_name text,
  sender_email text,
  message text not null,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  plan subscription_plan not null default 'free',
  status text not null default 'active',
  starts_at timestamptz not null default now(),
  ends_at timestamptz
);

create table public.credit_wallets (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table public.credit_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  amount integer not null,
  reason text not null,
  created_at timestamptz not null default now()
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  type campaign_type not null,
  city text,
  credits_spent integer not null default 0,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

alter table public.accounts enable row level security;
alter table public.listings enable row level security;
alter table public.inquiries enable row level security;
alter table public.subscriptions enable row level security;
alter table public.credit_wallets enable row level security;
alter table public.credit_transactions enable row level security;
alter table public.campaigns enable row level security;

create policy "public active listings" on public.listings for select using (status='active');
create policy "owners manage listings" on public.listings for all using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "account self read" on public.accounts for select using (auth.uid()=id);
create policy "account self update" on public.accounts for update using (auth.uid()=id);
create policy "owners read inquiries" on public.inquiries for select using (exists(select 1 from public.listings l where l.id=inquiries.listing_id and l.owner_id=auth.uid()));
create policy "public create inquiries" on public.inquiries for insert with check (true);
create policy "self subscriptions" on public.subscriptions for select using (account_id=auth.uid());
create policy "self wallet" on public.credit_wallets for select using (account_id=auth.uid());
create policy "self transactions" on public.credit_transactions for select using (account_id=auth.uid());
create policy "owners read campaigns" on public.campaigns for select using (exists(select 1 from public.listings l where l.id=campaigns.listing_id and l.owner_id=auth.uid()));
