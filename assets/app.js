let data = window.LIVARA_DATA || {listings:[],plans:[]};
const state = {city:'',category:'',available:false,verified:false,query:''};
const sb = window.LIVARA_SUPABASE || null;

function initials(name){return String(name||'').split(' ').filter(Boolean).map(x=>x[0]).join('').slice(0,2).toUpperCase()||'LV'}
function accentFor(value){const colors=['rose','violet','amber','emerald','cyan','blue','fuchsia','orange'];let h=0;for(const c of String(value||''))h=(h*31+c.charCodeAt(0))>>>0;return colors[h%colors.length]}
function normalizeRemote(x){return {
  id:x.id,name:x.name,city:x.city,district:x.district||'',category:x.category,verified:!!x.verified,
  available:!!x.available_today,online:false,rating:null,reviews:0,price:x.price_from??null,
  languages:[],bio:x.description||'Aktives Profil auf LIVARA.',accent:accentFor(x.id),remote:true
}}
function card(item, sponsored=false){
  const rating=item.rating?`★ ${item.rating}`:'Neu';
  const price=item.price!=null?`ab <strong>${item.price} €</strong>`:'Preis auf Anfrage';
  const meta=[item.city,item.district,item.category].filter(Boolean).join(' · ');
  return `<a class="card ${sponsored?'sponsored':''}" href="profile.html?id=${encodeURIComponent(item.id)}">
    <div class="visual ${item.accent}"><div class="portrait-mark">${initials(item.name)}</div><div class="badge-row">${sponsored?'<span class="badge">Sponsored</span>':''}${item.verified?'<span class="badge verified">✓ Verifiziert</span>':''}${item.available?'<span class="badge live">Heute</span>':''}</div></div>
    <div class="card-body"><div class="name-row"><div class="name">${item.name}</div><div class="rating">${rating}</div></div><div class="meta">${meta}</div><div class="price">${price}</div></div>
  </a>`
}
function filtered(){return data.listings.filter(x=>(!state.city||x.city===state.city)&&(!state.category||x.category===state.category)&&(!state.available||x.available)&&(!state.verified||x.verified)&&(!state.query||`${x.name} ${x.city} ${x.district||''} ${x.category}`.toLowerCase().includes(state.query.toLowerCase())))}
function render(){
  const root=document.querySelector('#listingGrid'); if(!root)return;
  const items=filtered(); const count=document.querySelector('#resultCount'); if(count)count.textContent=`${items.length} Treffer`;
  root.innerHTML=items.length?items.map((x,i)=>card(x,i<2)).join(''):`<div class="empty" style="grid-column:1/-1">Keine Treffer für diese Filter.</div>`;
}
function bindFilters(){
  const q=document.querySelector('#query'); const city=document.querySelector('#city'); const cat=document.querySelector('#category');
  if(q)q.addEventListener('input',e=>{state.query=e.target.value;render()});
  if(city)city.addEventListener('change',e=>{state.city=e.target.value;render()});
  if(cat)cat.addEventListener('change',e=>{state.category=e.target.value;render()});
  document.querySelectorAll('[data-filter]').forEach(b=>b.addEventListener('click',()=>{const k=b.dataset.filter;state[k]=!state[k];b.classList.toggle('active',state[k]);render()}));
  document.querySelector('#searchBtn')?.addEventListener('click',render);
}
function profile(){
  const root=document.querySelector('#profileRoot'); if(!root||!data.listings.length)return;
  const id=new URLSearchParams(location.search).get('id')||data.listings[0].id; const x=data.listings.find(a=>String(a.id)===String(id))||data.listings[0];
  const rating=x.rating?`★ ${x.rating} (${x.reviews||0} Bewertungen)`:'Neu auf LIVARA';
  const price=x.price!=null?`ab ${x.price} €`:'auf Anfrage';
  const languages=x.languages?.length?x.languages.join(', '):'nicht angegeben';
  root.innerHTML=`<div class="profile-head"><div class="profile-visual visual ${x.accent}"><div class="portrait-mark">${initials(x.name)}</div><div class="badge-row">${x.verified?'<span class="badge verified">✓ Verifiziert</span>':''}${x.available?'<span class="badge live">Heute verfügbar</span>':''}</div></div><div class="profile-info"><div class="eyebrow">${x.online?'● Online':'Aktives Profil'} · ${x.category}</div><h1>${x.name}</h1><div class="muted">${[x.city,x.district].filter(Boolean).join(' · ')} · ${rating}</div><div class="facts"><div class="fact"><span>Preis</span>${price}</div><div class="fact"><span>Sprachen</span>${languages}</div><div class="fact"><span>Status</span>${x.available?'Heute verfügbar':'Termine auf Anfrage'}</div></div><p class="muted" style="font-size:17px;line-height:1.7">${x.bio||''}</p><div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:22px"><button class="btn btn-primary" onclick="openInquiry('${String(x.id).replaceAll("'","\\'")}')">Anfrage senden</button><button class="btn btn-secondary" onclick="toast('Profil gespeichert.')">♡ Merken</button></div></div></div>`;
}
async function loadRemoteListings(){
  if(!sb?.url||!sb?.key)return;
  try{
    const res=await fetch(`${sb.url}/rest/v1/listings?select=id,name,category,city,district,description,price_from,verified,available_today&status=eq.active&order=published_at.desc.nullslast`,{headers:{apikey:sb.key,Authorization:`Bearer ${sb.key}`}});
    if(!res.ok)throw new Error(`HTTP ${res.status}`);
    const rows=await res.json();
    if(Array.isArray(rows)&&rows.length){data={...data,listings:rows.map(normalizeRemote)};render();profile();}
  }catch(err){console.warn('Supabase listings unavailable; using beta demo data.',err)}
}
function openInquiry(id){
  const x=data.listings.find(a=>String(a.id)===String(id)); if(!x)return;
  const existing=document.querySelector('#inquiryModal'); if(existing)existing.remove();
  const modal=document.createElement('div'); modal.id='inquiryModal'; modal.className='agegate';
  modal.innerHTML=`<div class="agebox"><div class="eyebrow">Anfrage an ${x.name}</div><h2>Kontaktanfrage</h2><form id="inquiryForm"><input class="field" name="sender_name" placeholder="Dein Name"><input class="field" name="sender_email" type="email" placeholder="E-Mail (optional)"><textarea class="field" name="message" required rows="5" placeholder="Deine Anfrage"></textarea><div style="display:flex;gap:10px;margin-top:12px"><button class="btn btn-primary" type="submit">Senden</button><button class="btn btn-secondary" type="button" id="cancelInquiry">Abbrechen</button></div></form></div>`;
  document.body.appendChild(modal); document.querySelector('#cancelInquiry').onclick=()=>modal.remove();
  document.querySelector('#inquiryForm').onsubmit=async(e)=>{
    e.preventDefault(); const f=new FormData(e.target); const payload={listing_id:x.id,sender_name:f.get('sender_name')||null,sender_email:f.get('sender_email')||null,message:f.get('message')};
    if(!x.remote||!sb){modal.remove();toast('Beta-Demo: Anfrage erfasst.');return;}
    try{const r=await fetch(`${sb.url}/rest/v1/inquiries`,{method:'POST',headers:{apikey:sb.key,Authorization:`Bearer ${sb.key}`,'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify(payload)});if(!r.ok)throw new Error(`HTTP ${r.status}`);modal.remove();toast('Anfrage erfolgreich gesendet.');}catch(err){toast('Anfrage konnte nicht gesendet werden.');console.error(err)}
  };
}
window.openInquiry=openInquiry;
function toast(msg){document.querySelector('.toast')?.remove();const t=document.createElement('div');t.className='toast';t.textContent=msg;document.body.appendChild(t);setTimeout(()=>t.remove(),2600)}
window.toast=toast;
function ageGate(){const g=document.querySelector('#ageGate');if(!g)return;if(localStorage.getItem('livara18')==='yes')g.classList.add('hidden');document.querySelector('#ageYes')?.addEventListener('click',()=>{localStorage.setItem('livara18','yes');g.classList.add('hidden')});}
function boost(){document.querySelector('#boostBtn')?.addEventListener('click',()=>{const bal=document.querySelector('#credits');let v=Number(bal.dataset.value||20);if(v>=5){v-=5;bal.dataset.value=v;bal.textContent=v+' Credits';toast('Beta-Demo: 3-Stunden-Boost aktiviert · 5 Credits verwendet.')}else toast('Nicht genügend Credits.')})}
document.addEventListener('DOMContentLoaded',()=>{ageGate();bindFilters();render();profile();boost();loadRemoteListings()});
