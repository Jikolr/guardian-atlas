/* Rebuild native transparent hero illustrations from the captured, prefab-linked rigs.
 * Run export_hero_illustrations.py first. This tool never executes game code.
 */
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const options = {};
for (let i = 2; i < process.argv.length; i += 2) options[process.argv[i].replace(/^--/, '')] = process.argv[i + 1];
const { chromium } = require(options.playwright || process.env.PLAYWRIGHT_MODULE || 'playwright');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const safe = value => value.replace(/[^A-Za-z0-9_-]/g, '-');

async function main() {
  if (!options.work || !options.runtime) throw Error('Supply --work and --runtime.');
  const work = path.resolve(options.work), core = path.join(__dirname, 'render_hero_illustration_core.js');
  const rulesFile = path.join(__dirname, 'hero_illustration_rules.json');
  const rules = read(rulesFile).illustrations;
  const rendererHash = hash(Buffer.concat([fs.readFileSync(core), fs.readFileSync(__filename), fs.readFileSync(options.runtime), fs.readFileSync(rulesFile)]));
  const jobs = read(path.join(work, 'jobs.json')).jobs.filter(job => !options.only || options.only.split(',').includes(job.illustrationId));
  const manifestFile = path.join(work, 'render-manifest.json');
  const manifest = fs.existsSync(manifestFile) ? read(manifestFile) : { schemaVersion: 1, illustrations: {}, errors: [] };
  fs.mkdirSync(path.join(work, 'pngs'), { recursive: true });
  const requested = new Set(jobs.map(job => job.id));
  manifest.errors = manifest.errors.filter(error => !requested.has(error.id));
  const browser = await chromium.launch({ headless: true, ...(options.chrome ? { executablePath: options.chrome } : { channel: 'msedge' }), args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const page = await browser.newPage();
    await page.goto('about:blank');
    await page.addScriptTag({ path: path.resolve(options.runtime) });
    await page.addScriptTag({ path: core });
    await page.evaluate(() => {
      const canvas = document.createElement('canvas'); document.body.append(canvas);
      window.illustrationRenderer = createHeroIllustrationRenderer(canvas);
      window.decodeRig = async (payload, job) => {
        if (window.currentIllustrationRig) illustrationRenderer.disposeRig(window.currentIllustrationRig);
        const source = payload.skeletons[job.rigIndex];
        if (!source || source.prefab !== job.prefab) throw Error('Exact prefab does not match render job.');
        const atlas = payload.atlases[source.atlas];
        if (!atlas) throw Error('Exact linked atlas is missing.');
        window.currentIllustrationRig = await illustrationRenderer.load({ atlasText: atlas.text, skeletonBytes: source.binary, imagesByPage: atlas.pages, skin: source.defaultSkin, scale: 1, sourcePremultipliedAlpha: true });
        return currentIllustrationRig.metadata;
      };
    });
    let completed = 0;
    for (const job of jobs) {
      const payloadPath = path.resolve(work, job.cacheFile);
      if (!payloadPath.startsWith(work + path.sep)) throw Error('Source cache is outside build directory.');
      const payload = read(payloadPath), contentHash = payload.contentSha256 || payload.sourceSha256;
      const previous = Object.values(manifest.illustrations).filter(row => row.jobId === job.id);
      if (previous.length && previous.every(row => row.rendererHash === rendererHash && row.contentHash === contentHash && Object.values(row.files).every(file => fs.existsSync(path.join(work, file.path))))) {
        completed++; continue;
      }
      try {
        const metadata = await page.evaluate(({ payload, job }) => decodeRig(payload, job), { payload, job });
        if (!String(metadata.version).startsWith('3.8.')) throw Error('Unsupported Spine version ' + metadata.version);
        const skins = metadata.skins.filter(skin => skin.attachments.length).map(skin => skin.name);
        if (!skins.includes(job.skin)) skins.unshift(job.skin || 'default');
        const animation = metadata.animations.find(animation => animation.name === job.animation);
        if (job.animation && !animation) throw Error('Prefab animation is missing: ' + job.animation);
        // An idle still at half a second allows authored effects to appear after
        // their opening keys while keeping all three exports on the same pose.
        const defaultTime = animation ? Math.min(0.5, animation.duration / 2) : 0;
        for (const skin of new Set(skins)) {
          const id = safe(job.id) + (skin !== job.skin ? '--skin-' + safe(skin) : '');
          const rule = rules[job.illustrationId] || {};
          const effectSlots = rule.effectSlots || job.effectSlots || [], excludeSlots = rule.excludeSlots || [];
          let time = rule.time ?? defaultTime;
          if (rule.time === undefined && metadata.slots.some(slot => slot.blendMode === 1 || slot.blendMode === 3 || effectSlots.includes(slot.name))) {
            const candidates = [...new Set([time, 0, ...(animation ? [animation.duration / 4, animation.duration / 2, animation.duration * 0.75] : [])])];
            // Some idle loops start with no visible emission. Find an authored
            // still with effects instead of incorrectly labelling the rig FX-free.
            for (const candidate of candidates) {
              const visible = await page.evaluate(input => illustrationRenderer.render({ ...input, rig: currentIllustrationRig, mode: 'effects', scale: 0.1, padding: 4, diagnostics: true }).diagnostics.visiblePixels, { skin, animation: job.animation || null, time: candidate, effectSlots, excludeSlots });
              if (visible) { time = candidate; break; }
            }
          }
          const result = { id, jobId: job.id, illustrationId: job.illustrationId, prefab: job.prefab, skin, animation: job.animation || null, time, metadata, rendererHash, contentHash, sourceSha256: job.sourceSha256, files: {} };
          let bounds;
          for (const [key, mode, suffix] of [['effects', 'combined', 'with-effects'], ['character', 'character', 'character'], ['effectsOnly', 'effects', 'effects-only']]) {
            const { png, ...details } = await page.evaluate(input => illustrationRenderer.render({ ...input, rig: currentIllustrationRig }), { skin, animation: job.animation || null, time, mode, effectSlots, excludeSlots, padding: 32, scale: 1, ...(bounds ? { bounds } : {}), diagnostics: true });
            if (mode === 'combined') bounds = details.bounds;
            if (details.empty || !details.diagnostics.visiblePixels) {
              if (key !== 'effectsOnly') throw Error('Empty ' + mode + ' render.');
              continue;
            }
            if (details.diagnostics.invalidPremultipliedPixels) throw Error('Invalid premultiplied alpha in ' + mode + '.');
            const bytes = Buffer.from(png.slice(png.indexOf(',') + 1), 'base64');
            const relative = 'pngs/' + id + '-' + suffix + '.png';
            fs.writeFileSync(path.join(work, relative), bytes);
            result.files[key] = { path: relative, bytes: bytes.length, sha256: hash(bytes), ...details };
          }
          // No FX means a single original PNG, without a misleading duplicate.
          if (!result.files.effectsOnly) delete result.files.effects;
          manifest.illustrations[id] = result;
        }
        completed++;
      } catch (error) {
        for (const [id, row] of Object.entries(manifest.illustrations)) if (row.jobId === job.id) delete manifest.illustrations[id];
        manifest.errors.push({ id: job.id, error: String(error.message).split('\n')[0] });
        console.error(job.id + ': ' + String(error.message).split('\n')[0]);
      }
      fs.writeFileSync(manifestFile, JSON.stringify(manifest));
      if ((completed + manifest.errors.length) % 10 === 0) console.log('Rendered ' + completed + '/' + jobs.length + ' rigs; ' + Object.keys(manifest.illustrations).length + ' illustrations; ' + manifest.errors.length + ' errors');
    }
    fs.writeFileSync(manifestFile, JSON.stringify(manifest));
    console.log(JSON.stringify({ completed, illustrations: Object.keys(manifest.illustrations).length, errors: manifest.errors }));
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
