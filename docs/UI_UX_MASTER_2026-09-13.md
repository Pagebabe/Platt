# LIVARA UI/UX Master – 2026-09-13

## Zweck

Diese Spezifikation ist die verbindliche Oberfläche-Linie der technischen Beta. Sie trennt Produktziel, Nutzerwege, Gestaltung und Abnahmekriterien. Ein geplanter Zustand gilt nicht als umgesetzt; ein umgesetzter Zustand gilt nicht als geprüft, solange der jeweilige Testnachweis fehlt.

## Zielgruppen

### Besucher / Suchende

Primäres Ziel: schnell ein passendes Profil finden, Angaben vergleichen und kontrolliert Kontakt aufnehmen.

Kernfragen der Oberfläche:
- Passt Ort, Kategorie und Preis?
- Ist die angezeigte Verfügbarkeit aktuell?
- Ist eine Platzierung Werbung?
- Wie merke oder kontaktiere ich das Profil?

Hauptweg:
`Entdecken -> Filtern -> Profil ansehen -> Merken oder Anfrage/WhatsApp -> private Unterhaltung`

Das frühere eigenständige Besucher-Feature „Vertrauen“ ist nicht Teil der Produktlinie. Verifizierung und Moderation bleiben technische Plattformfunktionen und können weiterhin als Statuskennzeichen erscheinen, werden aber nicht als eigener Besucherbereich inszeniert.

### Anbieter / Inserierende

Primäres Ziel: ein aktuelles Profil betreiben, relevante Anfragen bearbeiten und den Nutzen der Plattform erkennen.

Kernfragen der Oberfläche:
- Ist mein Profil vollständig, aktiv und aktuell?
- Welche Anfrage braucht jetzt Aufmerksamkeit?
- Welche Verfügbarkeit sehen Besucher?
- Was ist mein Prüfstatus?
- Welche Sichtbarkeitsfunktion ist aktiv?

Hauptweg:
`Anmelden -> Dashboard -> Profil/Verfügbarkeit pflegen -> Anfrage bearbeiten -> Reputation prüfen -> Sichtbarkeit steuern`

## Prioritätsregeln

1. Besucheroberfläche priorisiert Finden, Vergleichen und Kontakt vor Plattform-Erklärungen.
2. Anbieteroberfläche priorisiert Profilqualität, Aktualität und Anfragen vor Werbung.
3. Bezahlte Sichtbarkeit muss als Werbung erkennbar bleiben.
4. Verfügbarkeit ist eine aktuelle Anbieterangabe, keine Termingarantie.
5. Verifizierung beschreibt nur den konkret dokumentierten Prüfstatus und ist kein eigener Besucher-Featurebereich.
6. Fehlende, leere, geladene, gesperrte und fehlerhafte Zustände müssen verständlich benannt werden.
7. Mobile Kernhandlungen bleiben ohne horizontale Desktop-Struktur erreichbar.

## Visuelles System

Die Beta verwendet ab dieser Linie eine warme, helle Grundoberfläche mit ruhigen neutralen Flächen. Primäraktionen verwenden einen gedeckten Beerenton; Statusfarben werden sparsam und zusammen mit Text eingesetzt. Karten, Formulare, Navigation, Dashboard, rechtliche Seiten und Nachrichtenflächen verwenden dieselben Radien, Abstände, Fokuszustände und Oberflächentokens.

Technische Umsetzung: `assets/product-ui.css` liegt als kontrollierte Override-Schicht über dem bestehenden `assets/styles.css`. Dadurch bleibt die funktionierende Beta-Architektur unverändert und das Redesign kann isoliert geprüft oder zurückgenommen werden.

## Seitenrollen

- `index.html`: Entdecken, Filtern, regionale Einstiege und Anbieter-Einstieg.
- `profile.html`: Entscheidungsebene für Besucher mit Profilangaben, Verfügbarkeit, Bewertungen und Kontakt.
- `favorites.html`: ruhiger Vergleich gespeicherter Profile.
- `customer.html`: optionales Kundenkonto für geräteübergreifende Merkliste.
- `conversation.html`: private Fortsetzung einer Anfrage.
- `anbieter.html`: Nutzen- und Paketdarstellung für potenzielle Anbieter.
- `login.html`: Zugang und Registrierung für Anbieter.
- `dashboard.html`: täglicher Arbeitsleitstand für Profilstatus, Anfragen, Reputation und Sichtbarkeit.
- `provider.html`: Profil, Kontaktweg, Medien, Wochenplan und Verifizierung pflegen.
- `provider-inquiry.html`: konkrete Anfrage kommunizieren, qualifizieren und terminieren.
- `admin.html`: Moderations- und Prüfoberfläche.
- Rechteseiten: gleiche visuelle Linie, aber inhaltliche Launch-Gates bleiben ausdrücklich sichtbar.

## Abnahmekriterien

### Besucher

- Startseite zeigt ohne Erklärung Suchziel und Hauptaktion.
- Filter funktionieren weiterhin und führen zu Profilen.
- Es gibt keinen eigenständigen „Vertrauen“-Navigationspunkt, keine Vertrauenssektion auf der Startseite und keine separate Prüfbox auf Profilseiten.
- Profilseite zeigt Preis, Verfügbarkeit, Bewertungen und Kontakt verständlich.
- Anfrageformular und WhatsApp-Pfad bleiben erreichbar, sofern für das Profil vorhanden.
- Merkliste funktioniert mit und ohne Konto entsprechend der bestehenden Logik.
- Mobile Ansicht bietet die wichtigste Profilaktion dauerhaft erreichbar.

### Anbieter

- Anmeldung/Registrierung behält alle Pflichtzustimmungen.
- Dashboard zeigt operative Aufgaben vor Werbefunktionen.
- Profilbearbeitung behält Moderations-, Medien-, Verfügbarkeits- und Verifizierungslogik.
- Anfragebearbeitung trennt Kundennachricht, Pipeline-Status, Termin und interne Notiz.
- Werbefunktionen versprechen keine garantierten Anfragen.

### Plattform

- Bestehende Playwright-Kernprüfungen bleiben grün.
- Keine Rechteseite verliert Launch-Hinweise oder Pflichtplatzhalter.
- Aktive Hosting-Linie ist Netlify; andere Hostingdateien sind kein Nachweis eines aktiven Deployments.
- Ein kommerzieller Start bleibt gesperrt, solange Betreiberangaben, rechtliche Prüfung und aktivierte Zahlungsabwicklung nicht abgeschlossen sind.

## Nicht als abgeschlossen markieren

- kommerzielle Zahlungsabwicklung
- echte Betreiber-/Impressumsdaten
- externe rechtliche Freigabe
- vollständige produktive Sicherheitsfreigabe nur aufgrund eines UI-Tests

## Änderungsprinzip

UI-Texte und visuelle Prioritäten dürfen geändert werden, ohne bestehende Daten- oder Sicherheitslogik umzubauen. Änderungen an Authentifizierung, RLS, Moderationsrechten, Zahlungen oder Datenmodell benötigen ein eigenes technisches Gate und eigene Tests.
