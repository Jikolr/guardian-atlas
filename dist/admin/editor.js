(async()=>{
 const status=document.getElementById('status'),button=document.getElementById('start');
 try {
  const response=await fetch('settings.json');if(!response.ok)throw Error('Configuration unavailable');
  const s=await response.json();
  if(!s.authBaseUrl||!s.authReady){status.textContent='The editor is installed. Connect the GitHub application to the Cloudflare service to finish setup.';return;}
  if(new URL(s.authBaseUrl).protocol!=='https:')throw Error('The authentication service must use HTTPS.');
  if(!window.CMS)throw Error('Unable to load the editor. Reload the page.');
  if(location.origin!==new URL(s.siteUrl).origin){
   status.textContent='GitHub sign-in is available on the hosted website. Publish local changes first.';
   button.textContent='Open the hosted editor';button.disabled=false;
   button.onclick=()=>{location.href=s.siteUrl+'/admin/';};return;
  }
  status.textContent='Access is restricted to authorized site editors.';button.disabled=false;
  button.onclick=()=>{
   document.getElementById('welcome').hidden=true;
   CMS.init({config:{load_config_file:false,backend:{name:'github',repo:s.repo,branch:s.branch,base_url:s.authBaseUrl,auth_endpoint:'auth'},publish_mode:'editorial_workflow',site_url:s.siteUrl,display_url:s.siteUrl+'/newsletter.html',media_folder:'dist/uploads/newsletter',public_folder:'uploads/newsletter',collections:[{
    name:'newsletter',label:'Newsletters',label_singular:'Newsletter',folder:'newsletter/posts',create:true,delete:true,extension:'json',format:'json',slug:'{{slug}}',summary:'{{title}} · {{date}}',preview_path:'newsletter-{{slug}}.html',fields:[
     {name:'title',label:'Title',widget:'string'},
     {name:'date',label:'Display date',widget:'datetime',format:'YYYY-MM-DD',date_format:'DD/MM/YYYY',time_format:false},
     {name:'category',label:'Category',widget:'select',options:['Game files','Website news','Guides','Community']},
     {name:'summary',label:'Article list summary',widget:'text'},
     {name:'cover',label:'Cover image',widget:'image',required:false},
     {name:'published',label:'Show on the site after publishing',widget:'boolean',default:true,hint:'Turn this off and publish to remove the article from the site.'},
     {name:'body',label:'Article',widget:'markdown'},
     {name:'anchors',widget:'hidden',default:{}}
    ]
   },{
    name:'raid_videos',label:'Raid videos',label_singular:'Video',folder:'community/videos',create:true,delete:true,extension:'json',format:'json',slug:'{{slug}}',summary:'{{title}} · {{creator}}',preview_path:'raid-videos.html',fields:[
     {name:'title',label:'Video title',widget:'string'},
     {name:'url',label:'YouTube URL',widget:'string',hint:'https://www.youtube.com/watch?v=… or https://youtu.be/…'},
     {name:'creator',label:'Channel / creator name',widget:'string'},
     {name:'date',label:'Publication date',widget:'datetime',format:'YYYY-MM-DD',date_format:'DD/MM/YYYY',time_format:false},
     {name:'description',label:'Description / why watch',widget:'text',required:false},
     {name:'tags',label:'Boss, team, keywords',widget:'list',required:false},
     {name:'published',label:'Show on the site',widget:'boolean',default:true}
    ]
   },{
    name:'contact',label:'Contacts / About me',files:[{name:'profile',label:'My profile',file:'community/contact.json',fields:[
     {name:'title',label:'Introduction title',widget:'string'},
     {name:'bio',label:'Biography (English)',widget:'text'},
     {name:'discord',label:'Discord username',widget:'string'},
     {name:'email',label:'Email address',widget:'string'},
     {name:'channel',label:'YouTube channel URL',widget:'string'},
     {name:'image',label:'Profile picture',widget:'image'}
    ]}]
   }]}});
   CMS.registerPreviewStyle('../newsletter.css');
   CMS.registerPreviewTemplate('newsletter',createClass({render(){const e=this.props.entry;return h('article',{className:'article-body',style:{padding:'24px',maxWidth:'900px',margin:'auto'}},h('h1',{},e.getIn(['data','title'])),h('p',{},e.getIn(['data','summary'])),this.props.widgetFor('body'));}}));
  };
 }catch(e){status.textContent=e.message;}
})();
