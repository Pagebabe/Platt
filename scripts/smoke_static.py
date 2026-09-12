from pathlib import Path
from html.parser import HTMLParser

root=Path('.')
html=list(root.glob('*.html'))
missing=[]
class P(HTMLParser):
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        for key in ('href','src'):
            v=d.get(key)
            if not v or v.startswith(('#','http:','https:','mailto:','tel:','data:')):
                continue
            target=v.split('?',1)[0].split('#',1)[0]
            if target and not (root/target).exists():
                missing.append((self.file,target))
for f in html:
    p=P();p.file=str(f);p.feed(f.read_text(encoding='utf-8'))
if missing:
    raise SystemExit('Missing local links/assets: '+repr(missing))
required=[
    'index.html','profile.html','anbieter.html','login.html','reset.html','dashboard.html','provider.html','admin.html',
    'meldestelle.html','impressum.html','datenschutz.html','jugendschutz.html','anbieterregeln.html','nutzungsbedingungen.html','moderation.html',
    'assets/app.js','assets/auth.js','assets/login.js','assets/dashboard.js','assets/provider.js','assets/admin.js','assets/report.js',
    'assets/media.css','assets/media-public.js','assets/public-availability.js','_headers',
    'supabase/migrations/20260912_005_media_verification_admin.sql','supabase/migrations/20260912_006_registration_consent_gates.sql',
    'supabase/migrations/20260912_007_revoke_trigger_rpc.sql','supabase/migrations/20260912_008_index_new_foreign_keys.sql',
    'playwright.config.js','tests/e2e/public.spec.js'
]
for p in required:
    if not (root/p).exists():
        raise SystemExit('Missing required file: '+p)
print(f'Static smoke OK: {len(html)} HTML pages, no missing local links/assets, launch-critical files present.')
