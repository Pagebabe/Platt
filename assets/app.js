const data = window.LIVARA_DATA;
const state = {city:'',category:'',available:false,verified:false,query:''};

function initials(name){return name.split(' ').map(x=>x[0]).join('').slice(0,2).toUpperCase()}
function card(item, sponsored=false){
  return `<a class="card ${sponsored?'sponsored':''}" href="profile.html?id=${encodeURIComponent(item.id)}">
    <div class="visual ${item.accent}"><div class="portrait-mark">${initials(item.name)}</div><div class="badge-row">${sponsored?'<span class="badge">Sponsored</span>':''}${item.verified?'<span class="badge verified">✓ Verifiziert</span>':''}${item.available?'<span class="badge live">Heute</span>':''}</div></div>
    <div class="card-body"><div class="name-row"><div class="name">${item.name}</div><div class="rating">★ ${item.rating}</div></div><div class="meta">${item.city} · ${item.district} · ${item.category}</div><div class="price">ab <strong>${item.price} €</strong></div></div>
  </a>`
}
function filtered(){return data.listings.filter(x=>(!state.city||x.city===state.city)&&(!state.category||x.category===state.category)&&(!state.available||x.available)&&(!state.verified||x.verified)&&(!state.query||`${x.name} ${x.city} ${x.district} ${x.category}`.toLowerCase().includes(state.query.toLowerCase())))}
function render(){
  const root=document.querySelector('#listingGrid'); if(!root)return;
  const items=filtered(); document.querySelector('#resultCount').textContent=`${items.length} Treffer`;
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
  const root=document.querySelector('#profileRoot'); if(!root)return;
  const id=new URLSearchParams(location.search).get('id')||data.listings[0].id; const x=data.listings.find(a=>a.id===id)||data.listings[0];
  root.innerHTML=`<div class="profile-head"><div class="profile-visual visual ${x.accent}"><div class="portrait-mark">${initials(x.name)}</div><div class="badge-row">${x.verified?'<span class="badge verified">✓ Verifiziert</span>':''}${x.available?'<span class="badge live">Heute verfügbar</span>':''}</div></div><div class="profile-info"><div class="eyebrow">${x.online?'● Online':'Zuletzt heute aktiv'} · ${x.category}</div><h1>${x.name}</h1><div class="muted">${x.city} · ${x.district} · ★ ${x.rating} (${x.reviews} Bewertungen)</div><div class="facts"><div class="fact"><span>Preis</span>ab ${x.price} €</div><div class="fact"><span>Sprachen</span>${x.languages.join(', ')}</div><div class="fact"><span>Status</span>${x.available?'Heute verfügbar':'Termine auf Anfrage'}</div></div><p class="muted" style="font-size:17px;line-height:1.7">${x.bio}</p><div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:22px"><button class="btn btn-primary" onclick="toast('Anfrage wurde als Beta-Demo angelegt.')">Anfrage senden</button><button class="btn btn-secondary" onclick="toast('Profil gespeichert.')">♡ Merken</button></div></div></div>`;
}
function toast(msg){document.querySelector('.toast')?.remove();const t=document.createElement('div');t.className='toast';t.textContent=msg;document.body.appendChild(t);setTimeout(()=>t.remove(),2600)}
window.toast=toast;
function ageGate(){const g=document.querySelector('#ageGate');if(!g)return;if(localStorage.getItem('livara18')==='yes')g.classList.add('hidden');document.querySelector('#ageYes')?.addEventListener('click',()=>{localStorage.setItem('livara18','yes');g.classList.add('hidden')});}
function boost(){document.querySelector('#boostBtn')?.addEventListener('click',()=>{const bal=document.querySelector('#credits');let v=Number(bal.dataset.value||20);if(v>=5){v-=5;bal.dataset.value=v;bal.textContent=v+' Credits';toast('3-Stunden-Boost aktiviert · 5 Credits verwendet.')}else toast('Nicht genügend Credits.')})}
document.addEventListener('DOMContentLoaded',()=>{ageGate();bindFilters();render();profile();boost()});
