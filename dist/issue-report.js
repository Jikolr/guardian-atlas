'use strict';
(()=>{
 const button=document.createElement('button');button.id='report-issue';button.type='button';button.textContent='Report an issue';
 document.querySelector('#site-sidebar').append(button);
 const dialog=document.createElement('dialog');dialog.id='issue-dialog';dialog.setAttribute('aria-labelledby','issue-title');
 dialog.innerHTML='<form method="dialog"><button class="issue-close" aria-label="Close issue report">Close ×</button></form><h2 id="issue-title">Report an issue</h2><p>Describe what went wrong, copy the report, and send it to Discord <strong>newhorizons</strong> or by email. Nothing is sent automatically.</p><label for="issue-description">What happened? What did you expect?</label><textarea id="issue-description" rows="4" placeholder="For example: this portrait does not match the selected character."></textarea><label for="issue-context">Page context and report</label><textarea id="issue-context" rows="8" readonly></textarea><button id="issue-copy" type="button">Copy report</button> <a id="issue-email">Open email draft</a><p id="issue-status" role="status"></p>';
 document.body.append(dialog);
 const description=dialog.querySelector('#issue-description'),context=dialog.querySelector('#issue-context'),status=dialog.querySelector('#issue-status');
 let pageContext='';
 function update(){context.value=description.value.trim()+'\n\n'+pageContext;dialog.querySelector('#issue-email').href='mailto:nihalguardiantales@gmail.com?subject='+encodeURIComponent('Guardian Atlas: issue report')+'&body='+encodeURIComponent(context.value);}
 button.onclick=()=>{
  const url=new URL(location.href);
  if(['127.0.0.1','localhost',''].includes(url.hostname)){url.protocol='https:';url.host='jikolr.github.io';url.port='';url.pathname='/guardian-atlas/'+(location.pathname.split('/').pop()||'home.html');}
  const filters=[...document.querySelectorAll('main input[type="search"],main select')].filter(e=>e.value).slice(0,8).map(e=>(e.getAttribute('aria-label')||e.id||'Filter')+': '+e.value);
  pageContext=['Page: '+document.title,'Link: '+url.href,'Data snapshot: 3.55.0',...filters].join('\n');
  status.textContent='';update();dialog.showModal();description.focus();
 };
 description.addEventListener('input',update);
 dialog.querySelector('#issue-copy').onclick=async()=>{try{await navigator.clipboard.writeText(context.value);status.textContent='Report copied. Send it to newhorizons on Discord or use the email link.';}catch{context.focus();context.select();status.textContent='Select and copy the report above, then send it to Nihal.';}};
 dialog.addEventListener('close',()=>button.focus());
})();
