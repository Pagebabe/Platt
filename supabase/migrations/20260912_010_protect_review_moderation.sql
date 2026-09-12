create or replace function public.enforce_review_moderation_fields()
returns trigger language plpgsql security definer set search_path='public','app_private' as $$
begin
  if app_private.is_admin_impl() then return new; end if;
  new.status:=old.status;
  new.moderation_note:=old.moderation_note;
  new.reviewed_at:=old.reviewed_at;
  new.reviewed_by:=old.reviewed_by;
  new.rating:=old.rating;
  new.body:=old.body;
  new.inquiry_id:=old.inquiry_id;
  new.listing_id:=old.listing_id;
  return new;
end $$;
revoke all on function public.enforce_review_moderation_fields() from public,anon,authenticated;
drop trigger if exists trg_enforce_review_moderation on public.reviews;
create trigger trg_enforce_review_moderation before update on public.reviews for each row execute function public.enforce_review_moderation_fields();
