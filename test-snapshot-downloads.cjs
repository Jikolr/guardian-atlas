// Test the actual file browser with the prepared ZIPs; never publish a release.
// node test-snapshot-downloads.cjs --catalog PATH --archives-dir PATH [--url URL]
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs'), path = require('node:path');
const assert = require('node:assert/strict'), crypto = require('node:crypto');
const args = process.argv.slice(2);
const option = (name, fallback) => args.includes(name) ? args[args.indexOf(name) + 1] : fallback;
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

(async () => {
  const catalogPath = option('--catalog', 'dist/data/file-catalog.json');
  const archivesDir = option('--archives-dir');
  assert(archivesDir, '--archives-dir is required');
  const catalog = JSON.parse(fs.readFileSync(catalogPath));
  assert(catalog.currentVersion);
  assert(catalog.releaseBase.includes(catalog.releaseTag));
  assert(catalog.archives.length > 0);
  const known = new Map(catalog.archives.map(a => [a.name, a]));
  const seen = new Set();
  for (const row of catalog.files) {
    const key = row.section + '/' + row.path;
    assert(!seen.has(key), 'Duplicate catalog entry: ' + key);
    seen.add(key);
    if (row.archive) {
      assert(known.has(row.archive), row.archive);
      assert.equal(row.version, catalog.currentVersion);
      assert(row.offset >= 30 && row.offset + row.bytes <= known.get(row.archive).bytes);
    }
  }
  const row = catalog.files.find(r => r.section === 'decrypted' && r.path.startsWith('decoded/') &&
    r.archive && r.bytes > 0 && r.bytes < 2e6 && /\.json$/.test(r.path));
  assert(row, 'No small decoded table available for browser extraction test');
  const folder = row.path.slice(0, row.path.lastIndexOf('/') + 1);
  const folderRows = catalog.files.filter(r => r.section === row.section && r.path.startsWith(folder));
  const requiredArchives = [...new Set(folderRows.map(r => r.archive))];
  assert(folderRows.reduce((n, r) => n + r.bytes, 0) <= 250 * 1024 * 1024);
  const browser = await chromium.launch({channel: process.env.BROWSER_CHANNEL || 'msedge', headless: true});
  try {
    const page = await browser.newPage({acceptDownloads: true});
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    if (path.resolve(catalogPath) !== path.resolve('dist/data/file-catalog.json')) {
      await page.route('**/data/file-catalog.json', route => route.fulfill({contentType: 'application/json', body: JSON.stringify(catalog)}));
    }
    const query = new URLSearchParams({section: row.section, folder, file: row.path});
    await page.goto(option('--url', 'http://127.0.0.1:8766/') + 'files.html?' + query);
    await page.locator('#save-file').waitFor();
    if (catalog.releasePublished) assert.equal(await page.locator('#release-status a').getAttribute('href'), catalog.releaseURL);
    assert(await page.locator('#save-file').isDisabled());
    assert((await page.locator('#detail a').first().getAttribute('href')).includes('/' + catalog.releaseTag + '/'));
    await page.locator('#archive-input').setInputFiles(requiredArchives.map(name => path.resolve(archivesDir, name)));
    await page.waitForFunction(() => !document.querySelector('#save-file').disabled);
    const savedFile = page.waitForEvent('download');
    await page.locator('#save-file').click();
    const download = await savedFile;
    assert.equal(hash(fs.readFileSync(await download.path())), row.sha256);
    await page.locator('#folder-download').click();
    assert((await page.locator('#archive-links').innerText()).includes('.zip'));
    assert(await page.locator('#exact-folder').isEnabled());
    const savedFolder = page.waitForEvent('download');
    await page.locator('#exact-folder').click();
    const zipped = await savedFolder;
    const bytes = fs.readFileSync(await zipped.path());
    const expected = new Map(folderRows.map(r => [r.path, r]));
    let offset = 0, count = 0;
    while (bytes.readUInt32LE(offset) === 0x04034b50) {
      assert.equal(bytes.readUInt16LE(offset + 8), 0, 'Folder ZIP must use stored entries');
      const size = bytes.readUInt32LE(offset + 18), nameSize = bytes.readUInt16LE(offset + 26);
      const extra = bytes.readUInt16LE(offset + 28), name = bytes.subarray(offset + 30, offset + 30 + nameSize).toString('utf8');
      const dataOffset = offset + 30 + nameSize + extra, entry = expected.get(name);
      assert(entry, 'Unexpected folder ZIP member: ' + name);
      assert.equal(size, entry.bytes);
      assert.equal(hash(bytes.subarray(dataOffset, dataOffset + size)), entry.sha256);
      expected.delete(name);
      offset = dataOffset + size;
      count++;
    }
    assert.equal(expected.size, 0);
    assert.deepEqual(errors, []);
    console.log(`PASS: ${catalog.currentVersion}, ${catalog.archives.length} archive references, individual SHA-256 extraction, exact folder ZIP (${count} verified files), no page errors.`);
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
