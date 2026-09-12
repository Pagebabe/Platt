create index if not exists idx_listing_media_reviewed_by on public.listing_media(reviewed_by);
create index if not exists idx_listings_reviewed_by on public.listings(reviewed_by);
create index if not exists idx_moderation_audit_actor_id on public.moderation_audit(actor_id);
create index if not exists idx_reports_resolved_by on public.reports(resolved_by);
create index if not exists idx_verification_requests_listing_id on public.verification_requests(listing_id);
create index if not exists idx_verification_requests_reviewed_by on public.verification_requests(reviewed_by);
