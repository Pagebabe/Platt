# LIVARA Beta

Arbeitsname für eine moderne lokale Profil- und Anzeigenplattform.

## Status

- Öffentliche Suche/Listings: fertig
- Profilseite: fertig
- Anbieter-Dashboard: Beta-Demo
- Admin-Moderation: Beta-Demo
- Supabase-Projekt `Platt`: aktiv auf Free-Plan
- Öffentliche aktive Listings werden live aus Supabase geladen
- Kontaktanfragen werden für Live-Listings in `public.inquiries` gespeichert
- Demo-Daten bleiben als Fallback aktiv, solange keine Live-Listings vorhanden sind
- GitHub Pages Workflow vorhanden; die einmalige Pages-Aktivierung ist durch die GitHub-App-Berechtigung blockiert

## Sicherheit

Supabase meldet aktuell drei Tabellen ohne RLS: `listing_media`, `availability`, `reports`.
Sie werden im öffentlichen Beta-Frontend nicht verwendet. Eine vorbereitete, aber bewusst **nicht ausgeführte** Migration liegt unter `supabase/rls_hardening_pending.sql`.

## Lokal starten

```bash
python3 -m http.server 8080
```

Dann `http://localhost:8080` öffnen.
