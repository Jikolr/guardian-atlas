// Copy the supplied Spine runtime with one narrowly scoped UTF-8 reader fix.
// Usage: node prepare_hero_spine_runtime.cjs <source runtime directory> <output directory>
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function prepareHeroSpineRuntime(sourceDirectory, outputDirectory) {
  const sourcePath = path.resolve(sourceDirectory, 'spine-webgl.js');
  const original = fs.readFileSync(sourcePath, 'utf8');
  const start = original.indexOf('BinaryInput.prototype.readString = function ()');
  const end = original.indexOf('BinaryInput.prototype.readFloat', start);
  if (start < 0 || end < 0) throw new Error('Expected Spine 3.8 BinaryInput string reader was not found.');
  const reader = original.slice(start, end);
  const expression = 'var b = this.readByte();';
  if (reader.split(expression).length !== 2) throw new Error('String-reader patch no longer matches exactly once.');
  const fixedReader = reader.replace(expression, 'var b = this.readByte() & 255; // UTF-8 lead bytes must be unsigned.');
  const patched = original.slice(0, start) + fixedReader + original.slice(end);
  fs.mkdirSync(outputDirectory, { recursive: true });
  const outputPath = path.resolve(outputDirectory, 'spine-webgl.js');
  fs.writeFileSync(outputPath, patched);
  fs.copyFileSync(path.resolve(sourceDirectory, 'SPINE-LICENSE.txt'), path.resolve(outputDirectory, 'SPINE-LICENSE.txt'));
  const hash = value => crypto.createHash('sha256').update(value).digest('hex');
  const provenance = {
    sourcePath, sourceSha256: hash(original), outputSha256: hash(patched),
    patch: 'In BinaryInput.readString only, read the UTF-8 leading byte as unsigned with & 255. The source readByte uses DataView.getInt8, so b >> 4 otherwise cannot match UTF-8 cases 12, 13 and 14.',
    untouched: 'All source skeleton/atlas/image bytes, renderer geometry, UVs, animations and other binary readers are unchanged.',
    license: 'SPINE-LICENSE.txt',
    reproduce: 'node prepare_hero_spine_runtime.cjs <original-runtime-directory> <output-directory>'
  };
  fs.writeFileSync(path.resolve(outputDirectory, 'PATCH-PROVENANCE.json'), JSON.stringify(provenance, null, 2) + '\n');
  return { outputPath, ...provenance };
}

module.exports = { prepareHeroSpineRuntime };
if (require.main === module) {
  const [, , sourceDirectory, outputDirectory] = process.argv;
  if (!sourceDirectory || !outputDirectory) throw new Error('Supply source runtime directory and output directory.');
  console.log(JSON.stringify(prepareHeroSpineRuntime(sourceDirectory, outputDirectory), null, 2));
}
