#!/usr/bin/env node
/**
 * Generate a content-aware component catalogue.
 * The Git-compatible SHA-1 blob hash lets the app skip unchanged files on refresh.
 */
import { readdir, writeFile, stat, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const libraryRoot = path.join(projectRoot, 'public', 'components_library');
const manifestPath = path.join(libraryRoot, 'manifest.json');
const allowed = new Set(['.fcl', '.flc', '.zip']);
const ignoredDirectoryNames = new Set(['.git', '.github', 'node_modules', '__macosx']);

function gitBlobHash(buffer) {
  return createHash('sha1')
    .update(Buffer.from('blob ' + buffer.length + '\0'))
    .update(buffer)
    .digest('hex');
}

async function walk(dir, relative = '') {
  const entries = await readdir(dir, { withFileTypes: true });
  entries.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));
  const files = [];
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    if (entry.isSymbolicLink()) continue;
    const rel = relative ? `${relative}/${entry.name}` : entry.name;
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (ignoredDirectoryNames.has(entry.name.toLowerCase())) continue;
      files.push(...await walk(absolute, rel));
    } else if (entry.isFile() && allowed.has(path.extname(entry.name).toLowerCase())) {
      const info = await stat(absolute);
      if (!info.size) continue;
      const content = await readFile(absolute);
      files.push({ path: rel.split(path.sep).join('/'), hash: gitBlobHash(content), size: content.length });
    }
  }
  return files;
}

try {
  const files = await walk(libraryRoot);
  files.sort((a, b) => a.path.localeCompare(b.path, undefined, { numeric: true, sensitivity: 'base' }));
  const totalBytes = files.reduce((sum, file) => sum + file.size, 0);
  const manifest = {
    version: 2,
    generatedBy: 'Panel Craft build',
    totalFiles: files.length,
    totalBytes,
    files,
  };
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log(`[Panel Craft] Generated components_library/manifest.json with ${files.length} file(s), ${(totalBytes / 1024 / 1024).toFixed(1)} MB total.`);
  if (!files.length) console.warn('[Panel Craft] No .fcl, .flc or .zip files found. The public library will be empty.');
} catch (error) {
  console.error('[Panel Craft] Could not generate component-library manifest:', error);
  process.exitCode = 1;
}
