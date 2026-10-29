'use strict';
/* Translate presentation text only. Recovered game data, code and form values stay intact. */
(() => {
  const base = new URL('.', document.currentScript.src);
  const locales = {en:'English', es:'Español', fr:'Français', ja:'日本語', ko:'한국어', 'zh-Hans':'简体中文', 'zh-Hant':'繁體中文', id:'Bahasa Indonesia'};
  const storageKey = 'atlas-language';
  const excluded = 'script,style,pre,code,kbd,samp,textarea,svg,canvas,[translate="no"],[data-game-source],[data-i18n-ignore],[contenteditable="true"],.article-body,#site-language-bar,#table-body,.field-value,.field-key small,.internal-name,#raw,#dialogue,#keys,#positions,#room-dialogue p,#detail-id,#detail-source,.card-identifier,#objects option:not([value=""])';
  const textSources = new WeakMap(), attributeSources = new WeakMap(), articleSources = new WeakMap();
  const cache = new Map(), pending = new Set();
  let locale = 'en', messages = {}, folded = new Map(), patterns = [], serial = 0, frame = 0, manifestPromise;
  const normalize = value => value.replace(/\s+/g, ' ').trim();
  const escapeRegex = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  const bar = document.createElement('div');
  bar.id = 'site-language-bar';
  bar.setAttribute('data-i18n-ignore', '');
  bar.innerHTML = '<span id="site-language-status" role="status" aria-live="polite"></span><label for="site-language-select"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12h18M5 6.5h14M5 17.5h14"/></svg><span class="language-label">Language</span></label><select id="site-language-select"></select>';
  const select = bar.querySelector('select'), status = bar.querySelector('[role="status"]');
  for (const [value, name] of Object.entries(locales)) select.add(new Option(name, value));
  document.body.append(bar);

  function compilePatterns() {
    folded = new Map(Object.entries(messages).map(([source, target]) => [source.toLocaleLowerCase('en-US'), target]));
    patterns = Object.entries(messages).filter(([source]) => /\{\d+\}/.test(source) && source.replace(/\{\d+\}/g, '').replace(/[^\p{L}]/gu, '').length >= 3).map(([source, target]) => {
      const slots = [], fragments = source.split(/(\{\d+\})/g);
      const expression = fragments.map(part => {
        if (/^\{\d+\}$/.test(part)) { slots.push(part); return '(.*?)'; }
        return escapeRegex(part);
      }).join('');
      return {regex:new RegExp('^' + expression + '$', 'u'), target, slots, weight:source.replace(/\{\d+\}/g, '').length};
    }).sort((a,b) => b.weight-a.weight);
  }

  function t(value, depth = 0) {
    if (typeof value !== 'string' || locale === 'en') return value;
    const normalized = normalize(value);
    let translated = Object.hasOwn(messages, normalized) ? messages[normalized] : folded.get(normalized.toLocaleLowerCase('en-US'));
    if (translated === undefined && /^[\w./:-]*[_/:][\w./:-]*$/.test(normalized)) return value;
    if (translated === undefined && depth < 3) {
      for (const pattern of patterns) {
        const match = pattern.regex.exec(normalized);
        if (!match) continue;
        const captures = {};
        pattern.slots.forEach((slot, i) => { captures[slot] = t(match[i+1], depth + 1); });
        translated = pattern.target.replace(/\{\d+\}/g, slot => captures[slot] ?? slot);
        break;
      }
    }
    if (translated === undefined && depth < 3 && normalized.includes(' · ')) {
      translated = normalized.split(' · ').map(part => t(part, depth + 1)).join(' · ');
    }
    if (translated === undefined && depth < 3 && normalized.includes(' / ')) {
      translated = normalized.split(' / ').map(part => t(part, depth + 1)).join(' / ');
    }
    if (translated === undefined && depth < 3) {
      const leadingMarker = /^([·•●])\s+(.+)$/.exec(normalized);
      if (leadingMarker) translated = leadingMarker[1] + ' ' + t(leadingMarker[2], depth + 1);
    }
    if (translated === undefined) return value;
    return (value.match(/^\s*/)?.[0] || '') + translated + (value.match(/\s*$/)?.[0] || '');
  }

  function translateText(node) {
    if (!node.parentElement || node.parentElement.closest(excluded) || !node.nodeValue.trim()) return;
    // The browser derives an option's value from its text unless an explicit value is supplied.
    const option = node.parentElement.closest('option');
    if (option && !option.hasAttribute('value')) option.value = option.value;
    let record = textSources.get(node);
    if (!record || node.nodeValue !== record.rendered) record = {source:node.nodeValue};
    record.rendered = t(record.source);
    const date = node.parentElement.matches('time[datetime]') && node.parentElement.getAttribute('datetime');
    if (locale !== 'en' && date && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
      record.rendered = new Intl.DateTimeFormat(locale, {day:'numeric', month:'long', year:'numeric', timeZone:'UTC'}).format(new Date(date + 'T00:00:00Z'));
    }
    textSources.set(node, record);
    if (node.nodeValue !== record.rendered) node.nodeValue = record.rendered;
  }

  const displayAttributes = ['title','placeholder','aria-label','aria-description','alt'];
  function translateAttributes(element) {
    const blocker = element.closest(excluded);
    const accessibleCode = blocker === element && element.matches('pre,code,kbd,samp,canvas') && !element.parentElement?.closest(excluded);
    if (blocker && !accessibleCode) return;
    let records = attributeSources.get(element);
    if (!records) { records = {}; attributeSources.set(element, records); }
    const attributes = element.matches('meta[name="description"]') ? [...displayAttributes, 'content'] : displayAttributes;
    for (const attribute of attributes) {
      if (!element.hasAttribute(attribute)) continue;
      const current = element.getAttribute(attribute);
      let record = records[attribute];
      if (!record || current !== record.rendered) record = {source:current};
      record.rendered = t(record.source);
      records[attribute] = record;
      if (current !== record.rendered) element.setAttribute(attribute, record.rendered);
    }
  }

  function translate(root = document.documentElement) {
    if (root.nodeType === Node.TEXT_NODE) { translateText(root); return; }
    if (root.nodeType !== Node.ELEMENT_NODE) return;
    if (root.closest(excluded)) { translateAttributes(root); return; }
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, {
      acceptNode:node => {
        if (node.nodeType === Node.ELEMENT_NODE && node.matches(excluded)) { translateAttributes(node); return NodeFilter.FILTER_REJECT; }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    const elements = [root];
    let node;
    while ((node = walker.nextNode())) {
      if (node.nodeType === Node.TEXT_NODE) translateText(node); else elements.push(node);
    }
    for (const element of elements.reverse()) translateAttributes(element);
  }

  function translateArticles(pack) {
    document.querySelectorAll('.article-body[data-article-slug]').forEach(element => {
      if (!articleSources.has(element)) articleSources.set(element, element.innerHTML);
      const translated = pack?.articles?.[element.dataset.articleSlug];
      const valid = translated?.sourceSha256 === element.dataset.sourceHash;
      element.innerHTML = locale !== 'en' && valid ? translated.body : articleSources.get(element);
      element.lang = locale !== 'en' && valid ? locale : 'en';
      let notice = element.previousElementSibling?.classList.contains('article-language-notice') ? element.previousElementSibling : null;
      if (locale !== 'en' && !valid) {
        if (!notice) { notice = document.createElement('p'); notice.className = 'article-language-notice'; element.before(notice); }
        notice.setAttribute('data-i18n-ignore', '');
        notice.textContent = t(pack?.untranslatedArticles?.includes(element.dataset.articleSlug) ? 'Original English' : 'This article has changed since its translation. The original English is shown until the translation is updated.');
      } else notice?.remove();
    });
  }

  function updateWidget() {
    select.value = locale;
    select.setAttribute('aria-label', t('Website language'));
    bar.querySelector('.language-label').textContent = t('Language');
    document.querySelector('#site-nav-toggle')?.setAttribute('aria-label', t('☰ All sections'));
  }

  async function loadPack(language) {
    if (cache.has(language)) return cache.get(language);
    if (!manifestPromise) manifestPromise = fetch(new URL('data/i18n/manifest.json', base), {cache:'no-cache'}).then(response => {
      if (!response.ok) throw new Error('Language manifest unavailable');
      return response.json();
    }).catch(error => { manifestPromise = null; throw error; });
    const manifest = await manifestPromise;
    const entry = manifest.locales[language];
    if (!entry) throw new Error('Unknown language');
    const response = await fetch(new URL('data/i18n/' + entry.file + '?v=' + entry.sha256.slice(0,16), base));
    if (!response.ok) throw new Error('Language pack unavailable');
    const bytes = new Uint8Array(await response.arrayBuffer());
    // Static hosts may decompress .gz responses themselves, while Pages normally serves raw gzip.
    const data = bytes[0] === 31 && bytes[1] === 139 ? await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).text() : new TextDecoder().decode(bytes);
    const pack = JSON.parse(data);
    if (pack.locale !== language || !pack.messages) throw new Error('Invalid language pack');
    cache.set(language, pack);
    return pack;
  }

  async function setLanguage(language) {
    if (!Object.hasOwn(locales, language)) return false;
    const request = ++serial;
    bar.dataset.i18nLoading = '';
    status.textContent = language === 'en' ? '' : t('Loading translation…');
    try {
      const pack = language === 'en' ? null : await loadPack(language);
      if (request !== serial) return false;
      locale = language;
      messages = pack?.messages || {};
      compilePatterns();
      document.documentElement.lang = locale;
      translateArticles(pack);
      translate();
      updateWidget();
      try { localStorage.setItem(storageKey, locale); } catch { /* Private browsing may disable storage. */ }
      const url = new URL(location.href);
      if (url.searchParams.has('lang')) { url.searchParams.set('lang', locale); history.replaceState(history.state, '', url); }
      status.textContent = '';
      document.dispatchEvent(new CustomEvent('atlas:languagechange', {detail:{locale}}));
      return true;
    } catch (error) {
      if (request !== serial) return false;
      updateWidget();
      status.textContent = t('Translation could not be loaded. Please try again.');
      console.warn('Guardian Atlas translation unavailable:', error.message);
      return false;
    } finally {
      if (request === serial) delete bar.dataset.i18nLoading;
    }
  }

  select.addEventListener('change', () => setLanguage(select.value));
  new MutationObserver(changes => {
    for (const change of changes) {
      const node = change.target;
      const parent = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
      if (!parent || parent.closest(excluded)) continue;
      if (change.type === 'childList') change.addedNodes.forEach(child => pending.add(child));
      else pending.add(node);
    }
    if (!pending.size || frame) return;
    frame = requestAnimationFrame(() => {
      frame = 0;
      const roots = [...pending]; pending.clear();
      for (const root of roots) if (root.isConnected) translate(root);
    });
  }).observe(document.documentElement, {childList:true, characterData:true, subtree:true, attributes:true, attributeFilter:displayAttributes});

  window.AtlasI18n = Object.freeze({t, setLanguage, translate, get locale() { return locale; }, locales:Object.freeze(locales)});
  // Some data views normalize their URL before this lazy-loaded script runs.
  const navigationURL = performance.getEntriesByType('navigation')[0]?.name || location.href;
  let preferred = new URLSearchParams(location.search).get('lang') || new URL(navigationURL).searchParams.get('lang');
  if (!Object.hasOwn(locales, preferred)) {
    try { preferred = localStorage.getItem(storageKey); } catch { preferred = 'en'; }
  }
  updateWidget();
  setLanguage(Object.hasOwn(locales, preferred) ? preferred : 'en');
})();
