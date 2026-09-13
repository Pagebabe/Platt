alter table public.listings add column if not exists whatsapp_phone text;
alter table public.listings drop constraint if exists listings_whatsapp_phone_format;
alter table public.listings add constraint listings_whatsapp_phone_format check (whatsapp_phone is null or whatsapp_phone ~ '^\+[1-9][0-9]{7,14}$');
