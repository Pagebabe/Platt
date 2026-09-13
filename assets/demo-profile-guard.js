(()=>{const id=new URLSearchParams(location.search).get('id')||'';const local=(window.LIVARA_DATA?.listings||[]).some(x=>String(x.id)===String(id));if(local)window.LIVARA_SUPABASE=null})();
