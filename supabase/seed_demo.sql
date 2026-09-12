-- Optional demo-only seed. Do not run on a real production marketplace with live providers.
begin;
alter table public.listings disable trigger trg_enforce_listing_moderation;

insert into public.listings(owner_id,slug,name,category,city,district,description,price_from,verified,available_today,status,published_at,age,languages,tags,rating,review_count,response_time_minutes,is_demo)
values
(null,'demo-sophia-koeln','Sophia','Escort','Köln','Innenstadt','Demo-Profil: diskrete Begleitung in Köln mit ruhiger Kommunikation, klaren Angaben und direkter Anfragefunktion.',180,true,true,'active',now(),27,array['DE','EN'],array['Heute verfügbar','Verifiziert','Diskret'],4.9,38,35,true),
(null,'demo-mia-koeln','Mia','Massage','Köln','Ehrenfeld','Demo-Profil: entspannte Terminvereinbarung mit klaren Zeiten, transparenter Preisangabe und freundlicher Kommunikation.',120,true,true,'active',now(),31,array['DE','EN'],array['Heute verfügbar','Verifiziert','Entspannt'],4.8,24,45,true),
(null,'demo-lina-duesseldorf','Lina','Escort','Düsseldorf','Stadtmitte','Demo-Profil: modernes Profil mit verifiziertem Status, regelmäßigen Aktualisierungen und direkter Nachrichtenfunktion.',200,true,false,'active',now(),29,array['DE','EN','FR'],array['Verifiziert','Elegant'],4.7,19,60,true),
(null,'demo-nora-koeln','Nora','Massage','Köln','Deutz','Demo-Profil: kurzfristige Termine nach Verfügbarkeit mit direkter Anfrage über die Plattform.',100,false,true,'active',now(),33,array['DE'],array['Heute verfügbar','Spontan'],4.6,12,25,true),
(null,'demo-studio-rhein','Studio Rhein','Studio','Köln','Mülheim','Demo-Profil: verifiziertes Studio mit mehreren Angeboten, zentraler Kontaktverwaltung und klarer Verfügbarkeit.',150,true,true,'active',now(),null,array['DE','EN'],array['Studio','Verifiziert','Heute verfügbar'],4.9,61,20,true),
(null,'demo-lea-bonn','Lea','Escort','Bonn','Zentrum','Demo-Profil: übersichtliches Profil mit transparenter Verfügbarkeit und schneller Anfragefunktion für Bonn.',170,true,true,'active',now(),28,array['DE','EN'],array['Heute verfügbar','Verifiziert'],4.8,27,40,true),
(null,'demo-ava-essen','Ava','Massage','Essen','Rüttenscheid','Demo-Profil: klare Terminstruktur, ruhige Kommunikation und verifizierter Profilstatus.',110,true,false,'active',now(),30,array['DE'],array['Verifiziert','Ruhig'],4.7,16,50,true),
(null,'demo-luna-duesseldorf','Luna','Escort','Düsseldorf','Pempelfort','Demo-Profil: aktives Profil mit direkter Kontaktmöglichkeit, aktuellen Zeitfenstern und klarer Preisorientierung.',160,false,true,'active',now(),26,array['DE','EN'],array['Heute verfügbar','Neu'],4.5,9,30,true)
on conflict(slug) do update set
name=excluded.name,category=excluded.category,city=excluded.city,district=excluded.district,description=excluded.description,price_from=excluded.price_from,verified=excluded.verified,available_today=excluded.available_today,status=excluded.status,published_at=excluded.published_at,age=excluded.age,languages=excluded.languages,tags=excluded.tags,rating=excluded.rating,review_count=excluded.review_count,response_time_minutes=excluded.response_time_minutes,is_demo=excluded.is_demo;

alter table public.listings enable trigger trg_enforce_listing_moderation;
commit;
