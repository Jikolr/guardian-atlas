(async()=>{
 const status=document.getElementById('status'),button=document.getElementById('start');
 try {
  const response=await fetch('settings.json');if(!response.ok)throw Error('Configuration indisponible');
  const s=await response.json();
  if(!s.authBaseUrl||!s.authReady){status.textContent='L’éditeur est installé. Il reste à associer l’application GitHub au service Cloudflare.';return;}
  if(new URL(s.authBaseUrl).protocol!=='https:')throw Error('Le service de connexion doit utiliser HTTPS.');
  if(!window.CMS)throw Error('Impossible de charger l’éditeur. Recharge la page.');
  status.textContent='Accès réservé au propriétaire du site.';button.disabled=false;
  button.onclick=()=>{
   document.getElementById('welcome').hidden=true;
   CMS.init({config:{load_config_file:false,backend:{name:'github',repo:s.repo,branch:s.branch,base_url:s.authBaseUrl,auth_endpoint:'auth'},publish_mode:'editorial_workflow',site_url:s.siteUrl,display_url:s.siteUrl+'/newsletter.html',media_folder:'dist/uploads/newsletter',public_folder:'uploads/newsletter',collections:[{
    name:'newsletter',label:'Newsletters',label_singular:'Newsletter',folder:'newsletter/posts',create:true,delete:true,extension:'json',format:'json',slug:'{{slug}}',summary:'{{title}} · {{date}}',preview_path:'newsletter-{{slug}}.html',fields:[
     {name:'title',label:'Titre',widget:'string'},
     {name:'date',label:'Date affichée',widget:'datetime',format:'YYYY-MM-DD',date_format:'DD/MM/YYYY',time_format:false},
     {name:'category',label:'Catégorie',widget:'select',options:['Game files','Website news','Guides','Community']},
     {name:'summary',label:'Résumé sur la liste des articles',widget:'text'},
     {name:'cover',label:'Image de couverture',widget:'image',required:false},
     {name:'published',label:'Afficher sur le site après publication',widget:'boolean',default:true,hint:'Désactive cette option pour retirer un article du site lors de sa publication.'},
     {name:'body',label:'Article',widget:'markdown'},
     {name:'anchors',widget:'hidden',default:{}}
    ]
   }]}});
   CMS.registerPreviewStyle('../newsletter.css');
   CMS.registerPreviewTemplate('newsletter',createClass({render(){const e=this.props.entry;return h('article',{className:'article-body',style:{padding:'24px',maxWidth:'900px',margin:'auto'}},h('h1',{},e.getIn(['data','title'])),h('p',{},e.getIn(['data','summary'])),this.props.widgetFor('body'));}}));
  };
 }catch(e){status.textContent=e.message;}
})();
