-- Keep privileged implementations outside the exposed API schema.
grant usage on schema app_private to anon, authenticated;
grant execute on function app_private.is_admin_impl() to anon, authenticated;
revoke execute on function app_private.activate_boost_impl(uuid,integer,integer) from public, anon;
grant execute on function app_private.activate_boost_impl(uuid,integer,integer) to authenticated;

create or replace function public.is_admin()
returns boolean language sql stable security invoker set search_path=public,app_private as $$
  select app_private.is_admin_impl();
$$;

create or replace function public.activate_boost(p_listing_id uuid,p_credits integer default 5,p_hours integer default 3)
returns uuid language sql security invoker set search_path=public,app_private as $$
  select app_private.activate_boost_impl(p_listing_id,p_credits,p_hours);
$$;

grant execute on function public.is_admin() to anon, authenticated;
revoke execute on function public.activate_boost(uuid,integer,integer) from public, anon;
grant execute on function public.activate_boost(uuid,integer,integer) to authenticated;
