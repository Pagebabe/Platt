(()=>{
  let mountedCover=null;
  let lightbox=null;
  let currentIndex=0;
  let items=[];

  function collect(){
    return [...document.querySelectorAll('#profileGallery .profile-thumb')].map((thumb,index)=>{
      const img=thumb.querySelector('img');
      return {
        index,
        src:thumb.dataset.url||img?.src||'',
        alt:img?.alt||`Profilbild ${index+1}`,
        pos:thumb.dataset.pos||getComputedStyle(img||thumb).objectPosition||'50% 50%'
      };
    }).filter(x=>x.src);
  }

  function activeIndex(){
    const thumbs=[...document.querySelectorAll('#profileGallery .profile-thumb')];
    const found=thumbs.findIndex(x=>x.classList.contains('active'));
    return found>=0?found:0;
  }

  function ensureLightbox(){
    if(lightbox?.isConnected)return lightbox;
    lightbox=document.createElement('div');
    lightbox.className='profile-lightbox hidden';
    lightbox.setAttribute('role','dialog');
    lightbox.setAttribute('aria-modal','true');
    lightbox.setAttribute('aria-label','Profilgalerie groß anzeigen');
    lightbox.innerHTML=`<div class="profile-lightbox-stage"><button class="profile-lightbox-close" type="button" aria-label="Galerie schließen">×</button><button class="profile-lightbox-nav prev" type="button" aria-label="Vorheriges Bild">‹</button><figure><img alt=""><figcaption><span class="profile-lightbox-count"></span><span class="profile-lightbox-hint">Esc zum Schließen · Pfeiltasten zum Wechseln</span></figcaption></figure><button class="profile-lightbox-nav next" type="button" aria-label="Nächstes Bild">›</button></div>`;
    document.body.appendChild(lightbox);
    lightbox.querySelector('.profile-lightbox-close').addEventListener('click',close);
    lightbox.querySelector('.prev').addEventListener('click',()=>show(currentIndex-1));
    lightbox.querySelector('.next').addEventListener('click',()=>show(currentIndex+1));
    lightbox.addEventListener('click',e=>{if(e.target===lightbox)close()});
    return lightbox;
  }

  function show(index){
    items=collect();
    if(!items.length)return;
    currentIndex=(index+items.length)%items.length;
    const item=items[currentIndex];
    const box=ensureLightbox();
    const img=box.querySelector('img');
    img.src=item.src;
    img.alt=item.alt;
    img.style.objectPosition=item.pos;
    box.querySelector('.profile-lightbox-count').textContent=`${currentIndex+1} / ${items.length}`;
    const hasMultiple=items.length>1;
    box.querySelectorAll('.profile-lightbox-nav').forEach(x=>x.classList.toggle('hidden',!hasMultiple));
    box.classList.remove('hidden');
    document.documentElement.classList.add('gallery-open');
    box.querySelector('.profile-lightbox-close').focus();
  }

  function close(){
    if(!lightbox)return;
    lightbox.classList.add('hidden');
    document.documentElement.classList.remove('gallery-open');
    document.querySelector('#profileExpandBtn')?.focus();
  }

  function keyHandler(e){
    if(!lightbox||lightbox.classList.contains('hidden'))return;
    if(e.key==='Escape')close();
    if(e.key==='ArrowLeft')show(currentIndex-1);
    if(e.key==='ArrowRight')show(currentIndex+1);
  }

  function mount(){
    const cover=document.querySelector('#profileCover');
    const gallery=document.querySelector('#profileGallery');
    if(!cover||!gallery)return;
    if(cover===mountedCover&&document.querySelector('#profileExpandBtn'))return;
    mountedCover=cover;
    const btn=document.createElement('button');
    btn.id='profileExpandBtn';
    btn.className='profile-expand-button';
    btn.type='button';
    btn.setAttribute('aria-label','Profilbilder groß anzeigen');
    btn.innerHTML='<span aria-hidden="true">⛶</span> Vergrößern';
    btn.addEventListener('click',e=>{e.stopPropagation();show(activeIndex())});
    cover.appendChild(btn);
  }

  document.addEventListener('keydown',keyHandler);
  document.addEventListener('DOMContentLoaded',()=>{
    mount();
    new MutationObserver(mount).observe(document.body,{childList:true,subtree:true});
  });
})();
