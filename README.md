# LIVARA Beta

Eigenständige, dependency-freie klickbare Beta für einen modernen lokalen Anzeigen-/Marktplatz.

## Lokal starten

```bash
python3 -m http.server 8080
```

Dann `http://localhost:8080` öffnen.

## Seiten
- `/index.html` – Suche/Listings
- `/profile.html?id=sophia-koeln` – Profil
- `/dashboard.html` – Anbieter-Dashboard
- `/admin.html` – Moderation

## Backend-Vorbereitung
`supabase/schema.sql` enthält das vorbereitete Postgres-Schema inklusive erster RLS-Policies.

## Hinweis
Alle Profile und Kennzahlen in der Beta sind Demo-Daten. LIVARA ist ein Arbeitsname, keine geprüfte Marke.
