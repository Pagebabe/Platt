# Finaler E2E-/Smoke-Re-Test — 2026-09-11

## Ergebnis

**TECHNISCHE BETA: PASS mit einem manuellen Legal-Gate.**

## Behobene Punkte

- Supabase RLS vollständig: Security Advisor = 0 Findings.
- Least-Privilege GRANTs für anon/authenticated gesetzt.
- Rollen-Eskalation verhindert: Provider können `role` und `phone_verified` nicht selbst erhöhen.
- Anbieter können Moderationsstatus/Verifizierung ihrer Listings nicht selbst freischalten.
- Dashboard/Admin nicht mehr Demo-basiert: echte Auth-/RLS-Abfragen; unauthentifizierte Nutzer werden zum Login geleitet.
- Provider-Registrierung/Login und Profilanlage implementiert.
- Quick Boost atomar über geschützte RPC: Wallet-Abbuchung + Ledger + Kampagne; nur aktive eigene Listings.
- Sponsored-Markierung stammt aus aktiven Kampagnen, nicht mehr aus Position 1/2.
- Remote Profilinhalte werden vor HTML-Ausgabe escaped (Stored-XSS-Befund geschlossen).
- 18+-Gate gilt auch bei direktem Profilaufruf.
- Anfrageformular: Privacy-Akzeptanz, Honeypot/Timing, Längenlimits und DB-Duplikatschutz.
- Meldestelle schreibt echte Reports; anonyme Nutzer können Reports/Inquiries nicht auslesen.
- Mobile Pricing auf 1 Spalte; Header kompakter; Tabellen horizontal scrollbar; Inputs haben Labels/ARIA/focus state.
- Datenschutz/Jugendschutz/Meldestelle/Impressum-Routen vorhanden; robots noindex/nofollow für Beta.
- Netlify CSP, HSTS, nosniff, frame denial, referrer/permissions policy aktiv; Netlify meldet Header-Regel erfolgreich verarbeitet.
- Obsoleter GitHub-Pages-Workflow entfernt.
- GitHub CI hinzugefügt: `node --check` für alle JS-Dateien, statische Link-/Assetprüfung, Security-Header-Prüfung.

## Re-Test

- Netlify Production Deploy: READY, Branch `main`.
- GitHub Beta CI: PASS für JS-Syntax, Links/Assets, Header-Datei.
- Public RLS Listing SELECT: PASS.
- Public Inquiry INSERT: PASS und persistiert.
- Identische Inquiry innerhalb 10 Minuten: korrekt mit `duplicate inquiry` blockiert.
- Public Report INSERT: PASS und persistiert.
- Anonymous SELECT auf inquiries/reports: DENIED.
- Anonymous UPDATE auf listings: DENIED.
- Supabase Security Advisor: 0 Findings.
- Performance Advisor: nur `unused_index` INFO; erwartbar bei praktisch leerer Beta-Datenbank.
- E2E-Testdaten (Inquiry/Report) nach Prüfung gelöscht.
- Ein klar gekennzeichnetes systemeigenes Live-Testprofil bleibt aktiv, damit der echte Public-Data-Pfad testbar bleibt.

## Noch manuell vor öffentlicher Vermarktung

1. Vollständige echte Betreiberangaben im Impressum eintragen (Name/Firma, ladungsfähige Anschrift, Kontakt, ggf. Register/USt.).
2. Verantwortlichen/Kontakt in den Datenschutzhinweisen ergänzen und rechtlich prüfen lassen.
3. Ein echtes Anbieter-Konto über `login.html` registrieren und den E-Mail-Bestätigungsfluss einmal mit einer realen Adresse prüfen; das System erzeugt anschließend Account, Free-Abo und 20 Beta-Credits.

Keine dieser Angaben wurde erfunden.
