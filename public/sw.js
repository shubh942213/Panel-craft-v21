const CACHE_NAME='panel-craft-shell-v1';
const SHELL=['/','/index.html','/manifest.webmanifest','/icons/panel-craft.svg'];
self.addEventListener('install',event=>{
 event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(SHELL)).then(()=>self.skipWaiting()));
});
self.addEventListener('activate',event=>{
 event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('panel-craft-shell-')&&k!==CACHE_NAME).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});
self.addEventListener('fetch',event=>{
 const req=event.request,url=new URL(req.url);
 if(req.method!=='GET'||url.origin!==self.location.origin)return;
 // Keep license verification and the large component library network-controlled.
 if(url.pathname.startsWith('/.netlify/')||url.pathname.startsWith('/components_library/'))return;
 if(req.mode==='navigate'){
  event.respondWith(fetch(req).then(res=>{
   if(res.ok){const copy=res.clone();caches.open(CACHE_NAME).then(cache=>cache.put('/index.html',copy))}
   return res;
  }).catch(async()=> (await caches.match('/index.html')) || (await caches.match('/'))));
  return;
 }
 if(SHELL.includes(url.pathname)){
  event.respondWith(caches.match(req).then(hit=>hit||fetch(req).then(res=>{
   if(res.ok){const copy=res.clone();caches.open(CACHE_NAME).then(cache=>cache.put(req,copy))}
   return res;
  })));
 }
});
self.addEventListener('push',event=>{
 let data={};
 try{data=event.data?event.data.json():{}}catch(_){data={body:event.data?event.data.text():''}}
 const title=data.title||'Panel Craft';
 const options={
  body:data.body||'You have an update from Panel Craft.',
  icon:'/icons/panel-craft.svg',
  badge:'/icons/panel-craft.svg',
  tag:data.tag||'panel-craft-push',
  data:{url:data.url||'/'}
 };
 event.waitUntil(self.registration.showNotification(title,options));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=event.notification.data&&event.notification.data.url||'/';
 event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(clients=>{
  for(const client of clients){if('focus' in client){client.navigate(target);return client.focus()}}
  return self.clients.openWindow?self.clients.openWindow(target):undefined;
 }));
});
