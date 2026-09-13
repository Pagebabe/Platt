# LIVARA Beta

Arbeitsname für eine moderne lokale Profil- und Anzeigenplattform.

## Projektwahrheit

- Architektur: statische HTML/CSS/JavaScript-Beta mit Supabase.
- Aktive Hosting-Linie: Netlify, Projekt `platt-beta`.
- Öffentliche Beta: `https://platt-beta.netlify.app`.
- Vercel-Konfiguration liegt im Repository, es ist im verbundenen Vercel-Konto derzeit jedoch kein aktives Projekt hinterlegt.
- GitHub Pages ist nicht die aktive Hosting-Linie.
- Öffentliche Seiten sind in der Beta mit `noindex,nofollow` gekennzeichnet.

## Funktionsstand

- Öffentliche Suche und Listings vorhanden.
- Profilseiten mit Verfügbarkeit, Bewertungen, Prüfmerkmalen, Merkliste und Kontaktwegen vorhanden.
- Anbieter-Anmeldung, Dashboard, Profilpflege, Medien, Wochenplan, Verifizierungsantrag und Anfragebearbeitung vorhanden.
- Admin-Moderation für Profile, Medien, Bewertungen, Verifizierungen und Meldungen vorhanden.
- Supabase ist die Daten-, Authentifizierungs- und Speicherbasis der Beta.
- Demo-Daten können weiterhin als Fallback erscheinen, solange keine passenden Live-Listings geladen werden.

## UI/UX-Linie

Die verbindliche Produktoberfläche ist in `docs/UI_UX_MASTER_2026-09-13.md` dokumentiert. Das Redesign liegt als kontrollierte Override-Schicht in `assets/product-ui.css`, damit die bestehende Funktionsarchitektur nicht für rein visuelle Änderungen umgebaut werden muss.

## Launch-Gates

Nicht als kommerziell startbereit behandeln, solange diese Punkte offen sind:

- echte Betreiber- und Pflichtangaben,
- rechtliche Prüfung der Arbeitsfassungen,
- produktive Zahlungsabwicklung,
- gesonderte technische Sicherheitsfreigabe für den jeweiligen Produktivstand.

## Tests

Playwright deckt die wichtigsten öffentlichen Kernwege, Profilnavigation, Anfrageformular, WhatsApp-Link, Registrierungspflichten, ungültige Unterhaltungstoken und Meldestelle ab.

## Lokal starten

```bash
python3 -m http.server 8080
```

Danach `http://localhost:8080` öffnen.
